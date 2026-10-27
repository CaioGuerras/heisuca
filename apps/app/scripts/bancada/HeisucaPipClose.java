import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.UiAutomation;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

/** Ferramenta da bancada, executada como shell. Nunca entra no APK do aplicativo. */
public final class HeisucaPipClose {
    private static final String PACKAGE = "app.heisuca.player.teste.home";

    private static AccessibilityNodeInfo dismissTarget(UiAutomation ui) {
        for (AccessibilityWindowInfo window : ui.getWindows()) {
            if (!window.isInPictureInPictureMode()) continue;
            AccessibilityNodeInfo root = window.getRoot();
            if (root == null) continue;
            String pkg = String.valueOf(root.getPackageName());
            if (!PACKAGE.equals(pkg) && !"com.android.systemui".equals(pkg)) continue;
            for (AccessibilityNodeInfo.AccessibilityAction action : root.getActionList()) {
                if (action.getId() == AccessibilityNodeInfo.ACTION_DISMISS) return root;
            }
        }
        return null;
    }

    public static void main(String[] args) {
        try { run(args); }
        catch (Throwable error) {
            error.printStackTrace(System.err);
            System.exit(1); // Erro legível no artifact, em vez do KillApplicationHandler.
        }
    }

    private static void run(String[] args) throws Exception {
        // app_process não cria ActivityThread; a acessibilidade exige o Looper principal.
        Looper.prepareMainLooper();
        System.out.println("BANCADA_PIP: início do helper");
        boolean probe = args.length == 1 && "--probe".equals(args[0]);
        if (!probe && !(args.length == 1 && "--dismiss-pip".equals(args[0])))
            throw new IllegalArgumentException("Ação nativa inválida.");
        HandlerThread thread = new HandlerThread("bancada-pip");
        thread.start();
        UiAutomation ui = null;
        try {
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
                return;
            }
            long deadline = SystemClock.uptimeMillis() + 2500;
            AccessibilityNodeInfo target;
            do {
                target = dismissTarget(ui);
                if (target == null) SystemClock.sleep(50);
            } while (target == null && SystemClock.uptimeMillis() < deadline);
            if (target == null) {
                for (AccessibilityWindowInfo window : ui.getWindows()) {
                    AccessibilityNodeInfo root = window.getRoot();
                    System.out.println("BANCADA_JANELA: tipo=" + window.getType()
                            + " pip=" + window.isInPictureInPictureMode()
                            + " pacote=" + (root == null ? "sem raiz" : root.getPackageName())
                            + " ações=" + (root == null ? "sem raiz" : root.getActionList()));
                }
                throw new IllegalStateException("Janela PiP não oferece ACTION_DISMISS do Android.");
            }
            // AOSP 15: AbstractAccessibilityServiceConnection encaminha essa ação PiP
            // ao PipAccessibilityInteractionConnection, que chama MotionHelper.dismissPip.
            // Só uma ação; não chama o app, não força foco e não simula um pop.
            if (!target.performAction(AccessibilityNodeInfo.ACTION_DISMISS))
                throw new IllegalStateException("Android recusou ACTION_DISMISS do PiP.");
            System.out.println("BANCADA_PIP: ACTION_DISMISS do Android aceito");
        } finally {
            System.out.println("BANCADA_PIP: encerrando conexão");
            if (ui != null) UiAutomation.class.getMethod("disconnect").invoke(ui);
            thread.quitSafely();
        }
    }
}
