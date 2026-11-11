import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.UiAutomation;
import android.graphics.Rect;
import android.util.Xml;
import org.xmlpull.v1.XmlSerializer;
import java.io.StringWriter;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

/** Ferramenta da bancada, executada como shell. Nunca entra no APK do aplicativo. */
public final class HeisucaPipClose {
    private static final String PACKAGE = "app.heisuca.player.teste.home";

    private static AccessibilityNodeInfo pipTarget(UiAutomation ui, int actionId) {
        for (AccessibilityWindowInfo window : ui.getWindows()) {
            if (!window.isInPictureInPictureMode()) continue;
            AccessibilityNodeInfo root = window.getRoot();
            if (root == null) continue;
            String pkg = String.valueOf(root.getPackageName());
            if (!PACKAGE.equals(pkg) && !"com.android.systemui".equals(pkg)) continue;
            for (AccessibilityNodeInfo.AccessibilityAction action : root.getActionList()) {
                if (action.getId() == actionId) return root;
            }
        }
        return null;
    }

    /** Consulta instantânea das janelas; não espera a animação/vídeo ficar idle. */
    private static void writeNode(XmlSerializer xml, AccessibilityNodeInfo node, int depth) throws Exception {
        if (node == null || depth > 80) return;
        Rect bounds = new Rect();
        node.getBoundsInScreen(bounds);
        xml.startTag(null, "node");
        xml.attribute(null, "text", node.getText() == null ? "" : node.getText().toString());
        xml.attribute(null, "content-desc", node.getContentDescription() == null ? "" : node.getContentDescription().toString());
        xml.attribute(null, "package", String.valueOf(node.getPackageName()));
        xml.attribute(null, "resource-id", node.getViewIdResourceName() == null ? "" : node.getViewIdResourceName());
        xml.attribute(null, "enabled", Boolean.toString(node.isEnabled() && node.isVisibleToUser()));
        xml.attribute(null, "bounds", "[" + bounds.left + "," + bounds.top + "][" + bounds.right + "," + bounds.bottom + "]");
        for (int i = 0; i < node.getChildCount(); i++) writeNode(xml, node.getChild(i), depth + 1);
        xml.endTag(null, "node");
    }

    private static void dumpWindows(UiAutomation ui) throws Exception {
        StringWriter output = new StringWriter();
        XmlSerializer xml = Xml.newSerializer();
        xml.setOutput(output);
        xml.startTag(null, "hierarchy");
        for (AccessibilityWindowInfo window : ui.getWindows()) writeNode(xml, window.getRoot(), 0);
        xml.endTag(null, "hierarchy");
        xml.flush();
        System.out.println(output);
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
        boolean dump = args.length == 1 && "--dump".equals(args[0]);
        boolean show = args.length == 1 && "--show-pip-menu".equals(args[0]);
        if (!probe && !dump && !show && !(args.length == 1 && "--dismiss-pip".equals(args[0])))
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
            if (dump) {
                dumpWindows(ui);
                return;
            }
            if (probe) {
                System.out.println("BANCADA_PIP: janelas=" + ui.getWindows().size());
                return;
            }
            int actionId = show ? AccessibilityNodeInfo.ACTION_CLICK : AccessibilityNodeInfo.ACTION_DISMISS;
            String actionName = show ? "ACTION_CLICK" : "ACTION_DISMISS";
            long deadline = SystemClock.uptimeMillis() + 2500;
            AccessibilityNodeInfo target;
            do {
                target = pipTarget(ui, actionId);
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
                throw new IllegalStateException("Janela PiP não oferece " + actionName + " do Android.");
            }
            // AOSP 15: PipAccessibilityInteractionConnection encaminha CLICK ao menu
            // e DISMISS a MotionHelper.dismissPip. A ação vem da janela fixada.
            // Só uma ação; não chama o app, não força foco e não simula um pop.
            if (!target.performAction(actionId))
                throw new IllegalStateException("Android recusou " + actionName + " do PiP.");
            System.out.println("BANCADA_PIP: " + actionName + " do Android aceito");
        } finally {
            System.out.println("BANCADA_PIP: encerrando conexão");
            if (ui != null) UiAutomation.class.getMethod("disconnect").invoke(ui);
            thread.quitSafely();
        }
    }
}
