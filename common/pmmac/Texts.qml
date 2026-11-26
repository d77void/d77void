pragma Singleton
import QtQuick
import Quickshell

QtObject {

    readonly property string messageLanguage: {
        const preferred = String(Quickshell.env("LANGUAGE") || "").split(":")
        const candidates = Quickshell.env("PMMAC_LOCALE") ? [] : preferred
        for (const locale of candidates.concat(localeName("LC_MESSAGES"))) {
            const language = locale.split(/[_\-.@]/)[0].toLowerCase()
            if (language === "pt" || language === "en")
                return language
        }
        return "en"
    }
    readonly property var dateLocale: Qt.locale(localeName("LC_TIME"))
    readonly property var portuguese: ({
        "%1 remaining": "%1 restantes",
        "%1 until full": "%1 até à carga completa",
        "Application": "Aplicação",
        "Authentication could not be completed.": "Não foi possível concluir a autenticação.",
        "Authentication is unavailable.": "A autenticação está indisponível.",
        "Balanced": "Equilibrado",
        "Battery": "Bateria",
        "Brightness": "Brilho",
        "Charging": "A carregar",
        "Checking password…": "A verificar a palavra-passe…",
        "Click to configure": "Clicar para configurar",
        "Color intensity": "Intensidade da cor",
        "Confirm restart": "Confirmar reinício",
        "Confirm shutdown": "Confirmar encerramento",
        "Control Center": "Centro de controlo",
        "Controls": "Controlos",
        "Could not save dock pins.": "Não foi possível guardar as aplicações fixadas.",
        "Could not update wallpaper.": "Não foi possível atualizar o fundo.",
        "Enter password": "Introduzir palavra-passe",
        "Fully charged": "Carga completa",
        "Home": "Pasta pessoal",
        "Lock screen": "Bloquear ecrã",
        "Log out": "Terminar sessão",
        "Mute": "Silenciar",
        "Network": "Rede",
        "Niri disconnected": "Ligação ao Niri interrompida",
        "No images in this folder": "Não há imagens nesta pasta",
        "No matching applications": "Nenhuma aplicação encontrada",
        "No open applications": "Nenhuma aplicação aberta",
        "On battery": "Em bateria",
        "Open new instance": "Abrir nova instância",
        "Overview": "Visão geral",
        "Password not accepted.": "Palavra-passe incorreta.",
        "Performance": "Desempenho",
        "Pin to Dock": "Fixar no dock",
        "Plugged in": "Ligado à corrente",
        "Power Mode": "Modo de energia",
        "Power saver": "Poupança de energia",
        "Restart": "Reiniciar",
        "Search": "Pesquisar",
        "Search applications": "Pesquisar aplicações",
        "Session": "Sessão",
        "Shut down": "Desligar",
        "Suspend": "Suspender",
        "The authentication request could not be completed.": "Não foi possível concluir o pedido de autenticação.",
        "Unavailable": "Indisponível",
        "Unlock": "Desbloquear",
        "Unmute": "Reativar som",
        "Unpin from Dock": "Desafixar do dock",
        "Untitled window": "Janela sem título",
        "Up": "Pasta acima",
        "Updating wallpaper settings…": "A atualizar o fundo…",
        "User": "Utilizador",
        "Volume": "Volume",
        "Volume unavailable": "Volume indisponível",
        "Volume · Muted": "Volume · Silenciado",
        "Wallpaper": "Fundo",
        "Window": "Janela",
        "asleep": "Em suspensão",
        "connected": "Ligada",
        "connected (local only)": "Ligação local",
        "connected (site only)": "Ligação à rede",
        "connecting": "A ligar",
        "disconnected": "Desligada",
        "disconnecting": "A desligar",
        "unknown": "Desconhecida"
    })

    function localeName(category: string): string {
        const override = normalize(Quickshell.env("PMMAC_LOCALE"))
        if (override)
            return override
        const values = [Quickshell.env("LC_ALL"), Quickshell.env(category), Quickshell.env("LANG")]
        // A POSIX locale can be inherited from a terminal or supervisor.
        // Prefer an explicit regional setting when one is also available.
        for (const value of values) {
            const name = normalize(value)
            if (name && name !== "C" && name !== "POSIX")
                return name
        }
        return "C"
    }

    function normalize(value): string {
        return String(value || "").split(/[.@]/)[0].replace(/-/g, "_")
    }

    function tr(message: string): string {
        return messageLanguage === "pt" ? portuguese[message] ?? message : message
    }

    function clock(value: date): string {
        return dateLocale.toString(value, dateLocale.timeFormat(Locale.ShortFormat))
    }

    function day(value: date, compact: bool): string {
        const portugueseDate = dateLocale.name.split("_")[0] === "pt"
        const pattern = portugueseDate
            ? (compact ? "ddd, d MMM" : "dddd, d 'de' MMMM")
            : (compact ? "ddd d MMM" : "dddd, d MMMM")
        return dateLocale.toString(value, pattern)
    }
}
