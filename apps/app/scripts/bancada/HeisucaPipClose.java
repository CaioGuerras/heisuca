import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.UiAutomation;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;
import java.util.List;

/** Ferramenta da bancada, executada como shell. Nunca entra no APK do aplicativo. */
public final class HeisucaPipClose {
    private static AccessibilityNodeInfo closeButton(AccessibilityNodeInfo node) {
        if (node == null) return null;
        String pkg = String.valueOf(node.getPackageName());
        String id = String.valueOf(node.getViewIdResourceName());
        String label = String.valueOf(node.getContentDescription());
        if ("com.android.systemui".equals(pkg) && node.isVisibleToUser()
                && (id.endsWith(":id/dismiss") || id.endsWith(":id/pip_dismiss")
                || "Close".equalsIgnoreCase(label) || "Dismiss".equalsIgnoreCase(label)
                || "Fechar".equalsIgnoreCase(label))) return node;
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = closeButton(node.getChild(i));
            if (found != null) return found;
        }
        return null;
    }

    private static boolean clickClose(UiAutomation ui) {
        List<AccessibilityWindowInfo> windows = ui.getWindows();
        for (AccessibilityWindowInfo window : windows) {
            AccessibilityNodeInfo button = closeButton(window.getRoot());
            if (button != null && button.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                System.out.println("BANCADA_PIP: clique no botão real do SystemUI");
                return true;
            }
        }
        return false;
    }

    public static void main(String[] args) throws Exception {
        System.out.println("BANCADA_PIP: início do helper");
        boolean probe = args.length == 1 && "--probe".equals(args[0]);
        if (!probe && args.length != 4) throw new IllegalArgumentException("São necessários os limites do task PiP.");
        int left = probe ? 0 : Integer.parseInt(args[0]), top = probe ? 0 : Integer.parseInt(args[1]);
        int right = probe ? 1 : Integer.parseInt(args[2]), bottom = probe ? 1 : Integer.parseInt(args[3]);
        if (left < 0 || top < 0 || right <= left || bottom <= top)
            throw new IllegalArgumentException("Limites PiP inválidos.");
        HandlerThread thread = new HandlerThread("bancada-pip");
        thread.start();
        UiAutomation ui = null;
        try {
            // Mesma API de teste do comando uiautomator, disponível para o usuário shell.
            // As duas classes de conexão são internas do Android e ficam fora do SDK público.
            Class<?> connectionType = Class.forName("android.app.IUiAutomationConnection");
            Object connection = Class.forName("android.app.UiAutomationConnection")
                    .getDeclaredConstructor().newInstance();
            ui = (UiAutomation) UiAutomation.class.getDeclaredConstructor(Looper.class, connectionType)
                    .newInstance(thread.getLooper(), connection);
            System.out.println("BANCADA_PIP: conectando UiAutomation");
            UiAutomation.class.getMethod("connect").invoke(ui);
            System.out.println("BANCADA_PIP: conectado");
            AccessibilityServiceInfo info = ui.getServiceInfo();
            info.flags |= AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
                    | AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
            ui.setServiceInfo(info);
            if (probe) {
                System.out.println("BANCADA_PIP: janelas=" + ui.getWindows().size());
                return; // Diagnóstico sem toque, sem app e sem conta.
            }
            if (!clickClose(ui)) {
                // Abre o menu com um toque real, somente no task do nosso app identificado pelo host.
                long now = SystemClock.uptimeMillis();
                float x = (left + right) / 2f, y = (top + bottom) / 2f;
                for (int action : new int[]{MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP}) {
                    MotionEvent event = MotionEvent.obtain(now, SystemClock.uptimeMillis(), action, x, y, 0);
                    event.setSource(InputDevice.SOURCE_TOUCHSCREEN);
                    if (!ui.injectInputEvent(event, true)) throw new IllegalStateException("Toque PiP recusado.");
                    event.recycle();
                }
                // O menu dura 3,5 s. Não esperar idle (uiautomator dump pode consumir 10 s).
                long deadline = SystemClock.uptimeMillis() + 2500;
                boolean clicked = false;
                while (SystemClock.uptimeMillis() < deadline && !clicked) {
                    clicked = clickClose(ui);
                    if (!clicked) SystemClock.sleep(50);
                }
                if (!clicked) {
                    for (AccessibilityWindowInfo window : ui.getWindows()) {
                        AccessibilityNodeInfo root = window.getRoot();
                        System.out.println("BANCADA_JANELA: tipo=" + window.getType()
                                + " pacote=" + (root == null ? "sem raiz" : root.getPackageName()));
                    }
                    throw new IllegalStateException("Botão PiP do SystemUI não encontrado.");
                }
            }
        } finally {
            System.out.println("BANCADA_PIP: encerrando conexão");
            if (ui != null) UiAutomation.class.getMethod("disconnect").invoke(ui);
            thread.quitSafely();
        }
    }
}
