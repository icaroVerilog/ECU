#!/bin/bash
set -e

IVERILOG_FLAGS="-g2012"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RTL_DIR="$PROJECT_DIR/rtl"
TB_DIR="$PROJECT_DIR/sim/testbenches"
COMPILED_DIR="$PROJECT_DIR/sim/compiled"

mkdir -p "$COMPILED_DIR"

if [ $# -ne 1 ]; then
    echo "Uso: ./scripts/compile.sh <modulo>"
    exit 1
fi

MODULE="$1"

case "$MODULE" in

edge_detector)
    OUTPUT="$COMPILED_DIR/edge_detector"

    iverilog $IVERILOG_FLAGS \
        -o "$OUTPUT" \
        "$RTL_DIR/crankshaft/edge_detector.v" \
        "$TB_DIR/tb_edge_detector.v"

    vvp "$OUTPUT"
    ;;

injector_controller)
    OUTPUT="$COMPILED_DIR/injector_controller"

    iverilog $IVERILOG_FLAGS \
        -o "$OUTPUT" \
        "$RTL_DIR/injector/injector_controller.v" \
        "$RTL_DIR/injector/injector_timer.v" \
        "$TB_DIR/tb_injector_controller.v"

    vvp "$OUTPUT"
    ;;

*)
    echo "Módulo desconhecido: $MODULE"
    echo
    echo "Módulos disponíveis:"
    echo "  edge_detector"
    echo "  injector_controller"
    exit 1
    ;;
esac