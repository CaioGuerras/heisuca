import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.UiAutomation;
import android.graphics.Rect;
import android.util.Xml;
import org.xmlpull.v1.XmlSerializer;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;
import android.os.HandlerThread;
import android.os.Looper;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

/** Ferramenta da bancada, executada como shell. Nunca entra no APK do aplicativo. */
public final class HeisucaPipClose {
    private static final String PACKAGE = "app.heisuca.player.teste.home";
    private static final String[] ROTULOS = {"Tocar", "Pausar", "Voltar 10 segundos", "Avançar 10 segundos", "Próximo"};

    private static final class Leitura {
        final List<AccessibilityWindowInfo> janelas;
        final List<AccessibilityNodeInfo> raizes = new ArrayList<>();
        int quantidadeRaizes;
        Leitura(UiAutomation ui) {
            janelas = ui.getWindows();
            for (AccessibilityWindowInfo janela : janelas) {
                AccessibilityNodeInfo raiz = janela.getRoot();
                raizes.add(raiz);
                if (raiz != null) quantidadeRaizes++;
            }
        }
    }
    private static final class Tempos {
        final long inicio = SystemClock.uptimeMillis();
        long conectar = -1, primeiraLeitura = -1, abertura = -1, acharRotulo = -1;
        int aberturas;
        void imprimir() {
            System.out.println("BANCADA_TEMPOS: conectar_ms=" + conectar + " primeira_leitura_ms=" + primeiraLeitura
                    + " abertura_ms=" + abertura + " achar_rotulo_ms=" + acharRotulo + " aberturas=" + aberturas
                    + " total_ms=" + (SystemClock.uptimeMillis() - inicio));
        }
    }
    private static Leitura esperarJanelas(UiAutomation ui, long limite) throws Exception {
        Leitura leitura;
        do {
            leitura = new Leitura(ui);
            if (leitura.quantidadeRaizes > 0) return leitura;
            long restante = limite - SystemClock.uptimeMillis();
            if (restante <= 0) break;
            SystemClock.sleep(Math.min(50, restante));
        } while (SystemClock.uptimeMillis() < limite);
        diagnosticar(leitura);
        throw new IllegalStateException("Leitor de janelas vazio.");
    }
    private static AccessibilityNodeInfo pipTarget(Leitura leitura, int actionId) {
        for (int i = 0; i < leitura.janelas.size(); i++) {
            if (!leitura.janelas.get(i).isInPictureInPictureMode()) continue;
            AccessibilityNodeInfo raiz = leitura.raizes.get(i);
            if (raiz == null) continue;
            String pacote = String.valueOf(raiz.getPackageName());
            if (!PACKAGE.equals(pacote) && !"com.android.systemui".equals(pacote)) continue;
            for (AccessibilityNodeInfo.AccessibilityAction acao : raiz.getActionList())
                if (acao.getId() == actionId) return raiz;
        }
        return null;
    }
    private static int contarNos(AccessibilityNodeInfo no, int profundidade) {
        if (no == null || profundidade > 80) return 0;
        int total = 1;
        for (int i = 0; i < no.getChildCount(); i++) total += contarNos(no.getChild(i), profundidade + 1);
        return total;
    }
    private static void diagnosticar(Leitura leitura) {
        System.out.println("BANCADA_PIP: janelas=" + leitura.janelas.size() + " raizes=" + leitura.quantidadeRaizes);
        for (int i = 0; i < leitura.janelas.size(); i++) {
            AccessibilityWindowInfo janela = leitura.janelas.get(i);
            AccessibilityNodeInfo raiz = leitura.raizes.get(i);
            System.out.println("BANCADA_JANELA: tipo=" + janela.getType() + " pip=" + janela.isInPictureInPictureMode()
                    + " pacote=" + (raiz == null ? "sem raiz" : raiz.getPackageName()) + " nos=" + contarNos(raiz, 0));
        }
    }
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
    private static void dumpWindows(Leitura leitura) throws Exception {
        diagnosticar(leitura);
        if (leitura.quantidadeRaizes == 0) throw new IllegalStateException("Leitor de janelas vazio.");
        StringWriter output = new StringWriter();
        XmlSerializer xml = Xml.newSerializer();
        xml.setOutput(output);
        xml.startTag(null, "hierarchy");
        for (AccessibilityNodeInfo raiz : leitura.raizes) writeNode(xml, raiz, 0);
        xml.endTag(null, "hierarchy");
        xml.flush();
        System.out.println(output);
    }
    private static Rect acharBotao(AccessibilityNodeInfo no, String rotulo, int profundidade) {
        if (no == null || profundidade > 80) return null;
        if (no.isVisibleToUser() && no.isEnabled() && "com.android.systemui".contentEquals(
                no.getPackageName() == null ? "" : no.getPackageName())
                && (rotulo.contentEquals(no.getText() == null ? "" : no.getText())
                    || rotulo.contentEquals(no.getContentDescription() == null ? "" : no.getContentDescription()))) {
            Rect limites = new Rect();
            no.getBoundsInScreen(limites);
            if (!limites.isEmpty()) return limites;
        }
        for (int i = 0; i < no.getChildCount(); i++) {
            Rect encontrado = acharBotao(no.getChild(i), rotulo, profundidade + 1);
            if (encontrado != null) return encontrado;
        }
        return null;
    }
    private static Rect acharBotao(Leitura leitura, String rotulo) {
        for (AccessibilityNodeInfo raiz : leitura.raizes) {
            Rect encontrado = acharBotao(raiz, rotulo, 0);
            if (encontrado != null) return encontrado;
        }
        return null;
    }
    private static void procurarBotao(UiAutomation ui, String rotulo, Leitura leitura, Tempos tempos) throws Exception {
        boolean permitido = false;
        for (String candidato : ROTULOS) if (candidato.equals(rotulo)) permitido = true;
        if (!permitido) throw new IllegalArgumentException("Rótulo PiP inválido.");
        long limite = tempos.inicio + 8000;
        long inicioBusca = SystemClock.uptimeMillis();
        try {
            while (SystemClock.uptimeMillis() < limite) {
                Rect botao = acharBotao(leitura, rotulo);
                if (botao != null && SystemClock.uptimeMillis() < limite) {
                    tempos.acharRotulo = SystemClock.uptimeMillis() - inicioBusca;
                    dumpWindows(leitura);
                    System.out.println("BANCADA_BOTAO: x=" + botao.centerX() + " y=" + botao.centerY());
                    return;
                }
                boolean menuVisivel = false;
                for (String candidato : ROTULOS) if (acharBotao(leitura, candidato) != null) menuVisivel = true;
                if (!menuVisivel && tempos.aberturas == 0 && SystemClock.uptimeMillis() < limite) {
                    AccessibilityNodeInfo janelaPip = pipTarget(leitura, AccessibilityNodeInfo.ACTION_CLICK);
                    if (janelaPip != null) {
                        long inicioAbertura = SystemClock.uptimeMillis();
                        tempos.aberturas = 1;
                        try {
                            if (!janelaPip.performAction(AccessibilityNodeInfo.ACTION_CLICK))
                                throw new IllegalStateException("Android recusou ACTION_CLICK do PiP.");
                        } finally { tempos.abertura = SystemClock.uptimeMillis() - inicioAbertura; }
                        System.out.println("BANCADA_PIP: ACTION_CLICK do Android aceito");
                    }
                }
                long restante = limite - SystemClock.uptimeMillis();
                if (restante <= 0) break;
                SystemClock.sleep(Math.min(50, restante));
                leitura = esperarJanelas(ui, Math.min(limite, SystemClock.uptimeMillis() + 2500));
            }
            tempos.acharRotulo = SystemClock.uptimeMillis() - inicioBusca;
            dumpWindows(leitura);
            System.out.println("BANCADA_BOTAO_AUSENTE: prazo_ms=8000");
        } finally { tempos.acharRotulo = SystemClock.uptimeMillis() - inicioBusca; }
    }
    public static void main(String[] args) {
        try { run(args); }
        catch (Throwable error) { error.printStackTrace(System.err); System.exit(1); }
    }
    private static void run(String[] args) throws Exception {
        Tempos tempos = new Tempos();
        boolean probe = args.length == 1 && "--probe".equals(args[0]);
        boolean dump = args.length == 1 && "--dump".equals(args[0]);
        boolean show = args.length == 1 && "--show-pip-menu".equals(args[0]);
        boolean botao = args.length == 2 && "--pip-botao".equals(args[0]);
        if (!probe && !dump && !show && !botao && !(args.length == 1 && "--dismiss-pip".equals(args[0])))
            throw new IllegalArgumentException("Ação nativa inválida.");
        Looper.prepareMainLooper();
        System.out.println("BANCADA_PIP: início do helper");
        HandlerThread thread = new HandlerThread("bancada-pip");
        thread.start();
        UiAutomation ui = null;
        try {
            try {
                Class<?> connectionType = Class.forName("android.app.IUiAutomationConnection");
                Object connection = Class.forName("android.app.UiAutomationConnection").getDeclaredConstructor().newInstance();
                ui = (UiAutomation) UiAutomation.class.getDeclaredConstructor(Looper.class, connectionType)
                        .newInstance(thread.getLooper(), connection);
                UiAutomation.class.getMethod("connect").invoke(ui);
                AccessibilityServiceInfo info = ui.getServiceInfo();
                info.flags |= AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS | AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
                ui.setServiceInfo(info);
            } finally { tempos.conectar = SystemClock.uptimeMillis() - tempos.inicio; }
            long inicioLeitura = SystemClock.uptimeMillis();
            Leitura leitura;
            try { leitura = esperarJanelas(ui, Math.min(tempos.inicio + 8000, inicioLeitura + 2500)); }
            finally { tempos.primeiraLeitura = SystemClock.uptimeMillis() - inicioLeitura; }
            if (botao) { procurarBotao(ui, args[1], leitura, tempos); return; }
            if (dump || probe) { dumpWindows(leitura); return; }
            int actionId = show ? AccessibilityNodeInfo.ACTION_CLICK : AccessibilityNodeInfo.ACTION_DISMISS;
            String actionName = show ? "ACTION_CLICK" : "ACTION_DISMISS";
            long deadline = SystemClock.uptimeMillis() + 2500;
            AccessibilityNodeInfo target;
            do {
                target = pipTarget(leitura, actionId);
                if (target != null) break;
                SystemClock.sleep(50);
                leitura = new Leitura(ui);
            } while (SystemClock.uptimeMillis() < deadline);
            if (target == null) {
                diagnosticar(leitura);
                throw new IllegalStateException("Janela PiP não oferece " + actionName + " do Android.");
            }
            if (!target.performAction(actionId)) throw new IllegalStateException("Android recusou " + actionName + " do PiP.");
            System.out.println("BANCADA_PIP: " + actionName + " do Android aceito");
            if (show) {
                SystemClock.sleep(500);
                dumpWindows(esperarJanelas(ui, SystemClock.uptimeMillis() + 2500));
            }
        } finally {
            try { if (ui != null) UiAutomation.class.getMethod("disconnect").invoke(ui); }
            finally { thread.quitSafely(); tempos.imprimir(); }
        }
    }
}
