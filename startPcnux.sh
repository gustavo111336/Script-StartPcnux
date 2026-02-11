#!/bin/bash
# ==============================================================================
# NOME: Pcnux Manager Ultimate
# VERSÃO: 3.5.0-PRO
# AUTOR: Gemini (Adaptado para Termux)
# DATA: 2026-02-09
#
# DESCRIÇÃO:
# Script avançado para gerenciamento de sessões VNC no Termux (Android).
# Inclui verificação de dependências, correção automática de xstartup,
# gerenciamento de resolução, logs detalhados e menu interativo.
#
# REQUISITOS:
# - Termux
# - tigervnc
# - xfce4 (ou outro DE configurado)
# - xorg-server-xauth
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CONFIGURAÇÕES GLOBAIS E VARIÁVEIS
# ------------------------------------------------------------------------------

# Arquivos de Sistema
CONFIG_FILE="$HOME/.pcnux_config"
LOG_FILE="$HOME/pcnux_manager.log"
XSTARTUP_FILE="$HOME/.vnc/xstartup"
LOCK_DIR="/tmp/.X11-unix"

# Definições de Cores (ANSI)
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[38;5;196m'
C_GREEN='\033[38;5;46m'
C_YELLOW='\033[38;5;226m'
C_BLUE='\033[38;5;39m'
C_MAGENTA='\033[38;5;201m'
C_CYAN='\033[38;5;51m'
C_WHITE='\033[38;5;15m'
C_GRAY='\033[38;5;240m'

# Variáveis Padrão (serão sobrescritas se existir config)
DISPLAY_ID=":1"
PORT_BASE=5900
CUSTOM_RES="1600x900"
COLOR_DEPTH="24"
DESKTOP_ENV="xfce4"
APP_VIEWER="vnc://127.0.0.1"

# ------------------------------------------------------------------------------
# 2. FUNÇÕES DE UTILIDADE E UI
# ------------------------------------------------------------------------------

log_msg() {
    local TYPE=$1
    local MSG=$2
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$TYPE] $MSG" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${C_MAGENTA}"
    echo " ██████╗  ██████╗███╗   ██╗██╗   ██╗██╗  ██╗"
    echo " ██╔══██╗██╔════╝████╗  ██║██║   ██║╚██╗██╔╝"
    echo " ██████╔╝██║     ██╔██╗ ██║██║   ██║ ╚███╔╝ "
    echo " ██╔═══╝ ██║     ██║╚██╗██║██║   ██║ ██╔██╗ "
    echo " ██║     ╚██████╗██║ ╚████║╚██████╔╝██╔╝ ██╗"
    echo " ╚═╝      ╚═════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${C_CYAN}         MANAGER ULTIMATE v3.5${C_RESET}"
    echo -e "${C_GRAY}================================================${C_RESET}"
}

print_success() {
    echo -e "${C_GREEN}[✔] $1${C_RESET}"
    log_msg "INFO" "$1"
}

print_error() {
    echo -e "${C_RED}[✖] ERRO: $1${C_RESET}"
    log_msg "ERROR" "$1"
}

print_warn() {
    echo -e "${C_YELLOW}[!] ALERTA: $1${C_RESET}"
    log_msg "WARN" "$1"
}

print_info() {
    echo -e "${C_BLUE}[i] $1${C_RESET}"
}

press_enter() {
    echo ""
    echo -e "${C_GRAY}Pressione [ENTER] para continuar...${C_RESET}"
    read -r
}

loading_bar() {
    local duration=$1
    local columns=$(tput cols)
    local width=$((columns - 10))
    echo -ne "${C_CYAN}Carregando: [${C_RESET}"
    for ((i=0; i<=width; i++)); do
        echo -ne "${C_CYAN}#${C_RESET}"
        sleep "$duration"
    done
    echo -e "${C_CYAN}]${C_RESET}"
}

# ------------------------------------------------------------------------------
# 3. GERENCIAMENTO DE CONFIGURAÇÃO
# ------------------------------------------------------------------------------

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        # Cria config padrão se não existir
        save_config
    fi
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
# Configuração do Pcnux Manager
DISPLAY_ID="$DISPLAY_ID"
CUSTOM_RES="$CUSTOM_RES"
COLOR_DEPTH="$COLOR_DEPTH"
DESKTOP_ENV="$DESKTOP_ENV"
EOF
}

wizard_config() {
    print_header
    echo -e "${C_BOLD}--- Assistente de Configuração ---${C_RESET}"
    echo ""
    
    echo -ne "Defina a Resolução (Ex: 1280x720, 1600x900) [Atual: $CUSTOM_RES]: "
    read -r INPUT_RES
    if [ ! -z "$INPUT_RES" ]; then CUSTOM_RES=$INPUT_RES; fi

    echo -ne "Profundidade de Cor (16 ou 24) [Atual: $COLOR_DEPTH]: "
    read -r INPUT_DEPTH
    if [ ! -z "$INPUT_DEPTH" ]; then COLOR_DEPTH=$INPUT_DEPTH; fi

    echo -ne "Display ID (Ex: :1, :2) [Atual: $DISPLAY_ID]: "
    read -r INPUT_DISP
    if [ ! -z "$INPUT_DISP" ]; then DISPLAY_ID=$INPUT_DISP; fi

    save_config
    print_success "Configurações salvas com sucesso!"
    sleep 1
}

# ------------------------------------------------------------------------------
# 4. VERIFICAÇÃO E REPARO (AUTO-FIX)
# ------------------------------------------------------------------------------

check_dependencies() {
    print_info "Verificando dependências do sistema..."
    
    local DEPS=("tigervnc" "xfce4" "xorg-server-xauth" "grep" "sed")
    local MISSING=()

    for pkg in "${DEPS[@]}"; do
        if ! command -v "$pkg" &> /dev/null && ! dpkg -s "$pkg" &> /dev/null; then
            # Verificação especial para pacotes que não são comandos diretos
            if [ "$pkg" == "xfce4" ]; then
                if ! command -v xfce4-session &> /dev/null; then
                    MISSING+=("$pkg")
                fi
            elif [ "$pkg" == "xorg-server-xauth" ]; then
                 if ! command -v xauth &> /dev/null; then
                    MISSING+=("$pkg")
                fi
            else
                 MISSING+=("$pkg")
            fi
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        print_warn "Pacotes faltando: ${MISSING[*]}"
        echo -e "${C_YELLOW}Deseja tentar instalar automaticamente? (s/n)${C_RESET}"
        read -r INSTALL_OPT
        if [[ "$INSTALL_OPT" =~ ^[Ss]$ ]]; then
            pkg update -y && pkg upgrade -y
            pkg install -y "${MISSING[@]}"
            print_success "Dependências instaladas!"
        else
            print_error "O Pcnux não pode rodar sem dependências."
            return 1
        fi
    else
        print_success "Todas as dependências encontradas."
    fi
}

repair_xstartup() {
    # Esta função resolve o problema da TELA CINZA
    print_info "Diagnosticando arquivo xstartup..."
    
    mkdir -p "$HOME/.vnc"
    
    # Backup se existir
    if [ -f "$XSTARTUP_FILE" ]; then
        mv "$XSTARTUP_FILE" "${XSTARTUP_FILE}.bak.$(date +%s)"
        print_warn "xstartup antigo movido para backup."
    fi

    # Criando o novo xstartup otimizado
    cat > "$XSTARTUP_FILE" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
## Arquivo gerado pelo Pcnux Manager ##

# Limpa variáveis de sessão que podem conflitar
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Carrega recursos do X (opcional, mas bom ter)
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources

# Inicia o XFCE4
# Se você usar outro ambiente, altere a linha abaixo
exec startxfce4
EOF

    chmod +x "$XSTARTUP_FILE"
    print_success "Novo xstartup criado e configurado para XFCE4."
    print_info "Isso deve corrigir problemas de tela preta/cinza."
    sleep 2
}

# ------------------------------------------------------------------------------
# 5. CONTROLE DO SERVIDOR VNC
# ------------------------------------------------------------------------------

get_port_number() {
    # Extrai o número da porta baseada no display (ex: :1 -> 5901)
    local NUM=$(echo $DISPLAY_ID | sed 's/://')
    echo $((PORT_BASE + NUM))
}

check_running() {
    if [ -f "/tmp/.X${DISPLAY_ID:1}-lock" ]; then
        return 0 # Rodando
    else
        return 1 # Parado
    fi
}

clean_locks() {
    # Remove arquivos de trava mortos
    local LOCK_FILE="/tmp/.X${DISPLAY_ID:1}-lock"
    local SOCKET_FILE="/tmp/.X11-unix/X${DISPLAY_ID:1}"
    
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        print_info "Lock file removido."
    fi
    if [ -f "$SOCKET_FILE" ]; then
        rm -f "$SOCKET_FILE"
        print_info "Socket file removido."
    fi
}

start_pcnux() {
    print_header
    load_config
    
    echo -e "${C_CYAN}--- Seleção de Instância ---${C_RESET}"
    echo -ne "Digite o número do Display (Ex: 1 para localhost:1, 2 para localhost:2) [Padrão: 1]: "
    read -r DISP_NUM
    
    # Se o usuário não digitar nada, vira 1. Se digitar, vira :NUM
    if [ -z "$DISP_NUM" ]; then 
        DISPLAY_ID=":1"
    else 
        DISPLAY_ID=":$DISP_NUM"
    fi

    # Calcula a porta exata (5900 + ID)
    LOCAL_PORT=$((5900 + ${DISPLAY_ID#:}))

    if check_running; then
        print_warn "O Display $DISPLAY_ID já está em uso."
        echo -ne "Deseja forçar o fechamento e reiniciar? (s/n): "
        read -r RESTART_OPT
        if [[ "$RESTART_OPT" =~ ^[Ss]$ ]]; then
            vncserver -kill "$DISPLAY_ID" > /dev/null 2>&1
            clean_locks
        else
            return
        fi
    fi

    print_info "Iniciando Pcnux em localhost:$DISP_NUM (Porta $LOCAL_PORT)..."
    
    # Inicia com as novas configurações
    VNC_LOG_OUT=$(vncserver "$DISPLAY_ID" -geometry "$CUSTOM_RES" -depth "$COLOR_DEPTH" -localhost 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "Pcnux rodando em 127.0.0.1:$LOCAL_PORT"
        echo -e "${C_BLUE}Link: vnc://127.0.0.1:$LOCAL_PORT${C_RESET}"
        
        # Abre o RealVNC já no display correto
        termux-open "vnc://127.0.0.1:$LOCAL_PORT"
        log_msg "SUCCESS" "Iniciado no display $DISPLAY_ID"
    else
        print_error "Falha ao iniciar display $DISPLAY_ID"
        echo "$VNC_LOG_OUT" | tail -n 5
    fi
    press_enter
}

stop_pcnux() {
    print_header
    load_config
    print_info "Parando sessão VNC em $DISPLAY_ID..."
    
    vncserver -kill "$DISPLAY_ID" > /dev/null 2>&1
    
    # Força bruta se necessário
    if check_running; then
        print_warn "Kill padrão falhou. Tentando limpeza forçada..."
        clean_locks
    fi

    print_success "Sessão Pcnux encerrada."
    log_msg "INFO" "Sessão encerrada pelo usuário."
    sleep 1
}

kill_all_sessions() {
    print_header
    print_warn "Isso matará TODAS as sessões VNC ativas."
    echo -e "${C_RED}Tem certeza? (s/n)${C_RESET}"
    read -r KILL_OPT
    if [[ "$KILL_OPT" =~ ^[Ss]$ ]]; then
        vncserver -kill :* > /dev/null 2>&1
        rm -rf /tmp/.X11-unix/*
        rm -rf /tmp/.X*-lock
        print_success "Todas as sessões foram exterminadas."
    fi
    sleep 2
}

view_logs() {
    clear
    echo -e "${C_BOLD}=== LOGS DO SISTEMA (Últimas 20 linhas) ===${C_RESET}"
    if [ -f "$LOG_FILE" ]; then
        tail -n 20 "$LOG_FILE"
    else
        echo "Nenhum log encontrado."
    fi
    press_enter
}

# ------------------------------------------------------------------------------
# 6. MENU PRINCIPAL (LOOP)
# ------------------------------------------------------------------------------

show_menu() {
    print_header
    # Status Indicator
    if check_running; then
        echo -e " STATUS: ${C_GREEN}● ONLINE${C_RESET} ($DISPLAY_ID)"
    else
        echo -e " STATUS: ${C_RED}● OFFLINE${C_RESET}"
    fi
    echo -e "${C_GRAY}================================================${C_RESET}"
    echo ""
    echo -e "  ${C_BOLD}[1]${C_RESET} ➤ Iniciar Pcnux (Start)"
    echo -e "  ${C_BOLD}[2]${C_RESET} ■ Parar Pcnux (Stop)"
    echo -e "  ${C_BOLD}[3]${C_RESET} ⚙ Configurações (Resolução/Display)"
    echo -e "  ${C_BOLD}[4]${C_RESET} 🔧 REPARAR TELA CINZA (Fix xstartup)"
    echo -e "  ${C_BOLD}[5]${C_RESET} ☠ Matar Tudo (Kill All)"
    echo -e "  ${C_BOLD}[6]${C_RESET} ☰ Ver Logs"
    echo -e "  ${C_BOLD}[0]${C_RESET} ✖ Sair"
    echo ""
    echo -ne "${C_CYAN} Escolha uma opção: ${C_RESET}"
}

main() {
    # Inicialização
    load_config
    
    # Loop infinito do menu
    while true; do
        show_menu
        read -r OPTION
        
        case $OPTION in
            1)
                check_dependencies
                start_pcnux
                ;;
            2)
                stop_pcnux
                ;;
            3)
                wizard_config
                ;;
            4)
                repair_xstartup
                press_enter
                ;;
            5)
                kill_all_sessions
                ;;
            6)
                view_logs
                ;;
            0)
                echo -e "${C_MAGENTA}Saindo... Até logo!${C_RESET}"
                exit 0
                ;;
            *)
                echo -e "${C_RED}Opção inválida!${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 7. EXECUÇÃO
# ------------------------------------------------------------------------------

# Captura Ctrl+C para saída limpa
trap "echo -e '\n${C_RED}Interrompido pelo usuário.${C_RESET}'; exit 1" SIGINT

# Inicia o programa
main

