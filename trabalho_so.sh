#!/usr/bin/env bash
# ##############################################################
# #                                                          # #
# #                         IBMEC                           # #
# #                   Sistemas Operacionais                 # #
# #                   Código: IBM8940                        # #
# #             Professor: Luiz Fernando T. de Farias       # #
# #----------------------------------------------------------# #
# #  Equipe Desenvolvedora:                                  # #
# #  Aluno: $(whoami)                                        # #
# #  Aluno: ______________________________________________   # #
# #                                                          # #
# #  Rio de Janeiro, $(date +"%d de %B de %Y")                # #
# #  Hora do Sistema: $(date +"%H Horas e %M Minutos")        # #
# #  Semestre $([[ $(date +%m) -le 6 ]] && echo 1 || echo 2) de $(date +%Y)               # #
# ##############################################################

# ============================
# CONFIGURAÇÕES INICIAIS
# ============================
BASE_DIR=$(pwd)
BACKUP_DIR="$BASE_DIR/_backups"
mkdir -p "$BACKUP_DIR"

pausar() {
  echo
  read -rp "Pressione ENTER para continuar..." _
}

linha() { printf '%*s\n' "${1:-60}" | tr ' ' '#'; }

# ============================
# OPÇÃO 1 – Mini Navegador de Diretórios (restrito ao diretório de trabalho)
# ============================
mini_navegador() {
  local atual="$BASE_DIR"
  while true; do
    clear
    linha 60
    echo "# MINI NAVEGADOR (Diretório de trabalho: $BASE_DIR)"
    linha 60
    echo "Diretório atual: $atual"
    echo
    mapfile -t itens < <(ls -A "$atual" 2>/dev/null)
    if [ ${#itens[@]} -eq 0 ]; then
      echo "(vazio)"
    else
      for i in "${!itens[@]}"; do
        if [ -d "$atual/${itens[$i]}" ]; then
          echo "$((i+1))) [D] ${itens[$i]}"
        else
          echo "$((i+1))) [F] ${itens[$i]}"
        fi
      done
    fi
    echo "V) Voltar ao menu principal"
    echo
    read -rp "Selecione um número, ou 'V': " esc
    case "$esc" in
      [Vv]) break ;;
      ''|*[!0-9]*) continue ;;
      *)
        idx=$((esc-1))
        [ $idx -ge 0 ] && [ $idx -lt ${#itens[@]} ] || continue
        alvo="$atual/${itens[$idx]}"
        if [ -d "$alvo" ]; then
          novo=$(cd "$alvo" 2>/dev/null && pwd)
          case "$novo" in
            "$BASE_DIR"|"$BASE_DIR"/*) atual="$novo" ;;
            *) echo "Não é permitido sair do diretório de trabalho."; pausar ;;
          esac
        else
          ${VISUAL:-vi} "$alvo"
        fi
      ;;
    esac
  done
}

# ============================
# OPÇÃO 2 – Mini Gerenciador de Tarefas (CPU/Memória/Disco)
# ============================
mini_gerenciador() {
  while true; do
    clear
    linha 60
    echo "# MINI GERENCIADOR DE TAREFAS"
    linha 60
    echo "Uptime: $(uptime -p)"
    echo "Processos: $(ps -e --no-headers | wc -l)"
    echo
    echo "== CPU (load average) =="
    uptime | sed 's/.*load average: /load average: /'
    echo
    echo "== Memória (free -h) =="
    free -h
    echo
    echo "== Disco (df -h .) =="
    df -h .
    echo
    read -rp "ENTER para atualizar | q para voltar: " opt
    case "$opt" in
      q|Q) break;;
      *) :;;
    esac
  done
}

# ============================
# OPÇÃO 3 – Criar Backup de um Diretório
# ============================
criar_backup() {
  clear
  echo "Diretório base permitido: $BASE_DIR"
  read -rp "Informe o caminho do diretório a ser backupeado (relativo ou absoluto): " SRC
  [ -z "$SRC" ] && { echo "Caminho inválido."; pausar; return; }
  SRC=$(cd "$SRC" 2>/dev/null && pwd)
  if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
    echo "Diretório não encontrado."; pausar; return
  fi
  case "$SRC" in
    "$BASE_DIR"|"$BASE_DIR"/*) : ;; 
    *) echo "Permitido apenas dentro do diretório de trabalho."; pausar; return ;;
  esac
  ts=$(date +%Y%m%d-%H%M%S)
  nome=$(basename "$SRC")
  arq="$BACKUP_DIR/${nome}__$ts.tar.gz"
  echo "Criando backup em: $arq"
  tar -czf "$arq" -C "$SRC" .
  if [ $? -eq 0 ]; then
    echo "Backup criado com sucesso!"
  else
    echo "Falha ao criar backup."
  fi
  pausar
}

# ============================
# OPÇÃO 4 – Restaurar Backup de um Diretório
# ============================
restaurar_backup() {
  clear
  echo "Backups disponíveis em: $BACKUP_DIR"
  mapfile -t bks < <(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
  if [ ${#bks[@]} -eq 0 ]; then
    echo "Nenhum backup encontrado."; pausar; return
  fi
  for i in "${!bks[@]}"; do
    echo "$((i+1))) $(basename "${bks[$i]}")"
  done
  echo
  read -rp "Selecione o número do backup: " n
  case "$n" in
    ''|*[!0-9]*) echo "Entrada inválida."; pausar; return ;;
  esac
  idx=$((n-1))
  [ $idx -ge 0 ] && [ $idx -lt ${#bks[@]} ] || { echo "Opção inválida."; pausar; return; }
  arq="${bks[$idx]}"

  read -rp "Informe o diretório de destino (será criado se não existir): " DST
  [ -z "$DST" ] && { echo "Destino inválido."; pausar; return; }
  mkdir -p "$DST"
  DST=$(cd "$DST" 2>/dev/null && pwd)
  case "$DST" in
    "$BASE_DIR"|"$BASE_DIR"/*) : ;;
    *) echo "Restauração permitida apenas dentro do diretório de trabalho."; pausar; return ;;
  esac

  echo "Restaurando $(basename "$arq") para $DST ..."
  tar -xzf "$arq" -C "$DST"
  if [ $? -eq 0 ]; then
    echo "Restauração concluída!"
  else
    echo "Falha na restauração."
  fi
  pausar
}

# ============================
# MENU PRINCIPAL
# ============================
while true; do
  clear
  echo "##############################################################"
  echo "# IBMEC                                                # Turma: 8001 #"
  echo "# Sistemas Operacionais                                #"
  echo "# Código: IBM8940                                       #"
  echo "# Professor: Luiz Fernando T. de Farias                 #"
  echo "#--------------------------------------------------------------#"
  echo "# Equipe Desenvolvedora:                                     #"
  echo "# Aluno: $(whoami)                                           #"
  echo "# Aluno: ______________________________________________      #"
  echo "# Rio de Janeiro, $(date +"%d de %B de %Y")                        #"
  echo "# Hora do Sistema: $(date +"%H Horas e %M Minutos")                  #"
  echo "# Semestre $([[ $(date +%m) -le 6 ]] && echo 1 || echo 2) de $(date +%Y)                      #"
  echo "##############################################################"
  echo
  echo "Menu de Escolhas:"
  echo "  1) Mini navegador de diretórios"
  echo "  2) Mini gerenciador de tarefas (CPU/Memória/Disco)"
  echo "  3) Criar backup de um diretório"
  echo "  4) Restaurar backup"
  echo "  5) Finalizar o programa"
  echo
  read -rp "Selecione uma opção: " op
  case "$op" in
    1) mini_navegador ;;
    2) mini_gerenciador ;;
    3) criar_backup ;;
    4) restaurar_backup ;;
    5) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida."; pausar ;;
  esac
done
