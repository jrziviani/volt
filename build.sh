#!/bin/sh

clean() {
    echo "*****************************************"
    echo "** Removing old build                  **"
    echo "*****************************************"
    [[ -d bin ]] && rm -fr bin
    [[ -d .build ]] && rm -fr .build
}

debug() {
    echo "*****************************************"
    echo "** Building debug binaries             **"
    echo "*****************************************"
    local verbose="$1"
    mkdir -p .build/debug
    cd .build/debug
    cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../..
    [[ $? -eq 0 ]] || exit 1
    [[ "$verbose" == 1 ]] && VERBOSE=1 make -j$(nproc) || make -j$(nproc)
    mkdir -p ../../bin/debug
    cp -a bin/* ../../bin/debug
    cd ../..
}

release() {
    echo "*****************************************"
    echo "** Building release binaries           **"
    echo "*****************************************"
    local verbose="$1"
    mkdir -p .build/release
    cd .build/release
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../..
    [[ $? -eq 0 ]] || exit 1
    [[ "$verbose" == 1 ]] && VERBOSE=1 make -j$(nproc) || make -j$(nproc)
    mkdir -p ../../bin/release
    cp -a bin/* ../../bin/release
    cd ../..
}

coverage() {
    echo "*****************************************"
    echo "** Running test cases                  **"
    echo "*****************************************"
    mkdir -p .build/release
    cd .build/release
    cmake -DCMAKE_BUILD_TYPE=Release -Denable-test=ON ../..
    [[ $? -eq 0 ]] || exit 1
    make coverage
    mkdir -p ../../bin/release
    cp -a bin/* ../../bin/release
    cd ../..
}

usage() {
    local error="$1"
    local program="$2"
    local option="$3"

    [[ "$error" == 1 ]] && echo "option $option not recognized"
    cat <<-EOF
        Usage: $program [options]

            --rebuild       make a clear build
            --clear         delete build artifacts
            --debug         build with debug symbols [default]
            --release       build with optimizations on
            --test          run test cases and test coverage
            --static        build static library
            --verbose       build verbose mode
EOF
    exit 1
}

main() {
    local rebuild=0
    local test=0
    local clear=0
    local debug=0
    local verbose=0
    local static=0

    while [[ "$1" == --* ]]; do
        local opt="$1"
        shift

        case "$opt" in
            --rebuild)
                rebuild=1
                ;;
            --test)
                test=1
                ;;
            --clear)
                clear=1
                ;;
            --debug)
                debug=1
                ;;
            --release)
                release=1
                ;;
            --static)
                static=1
                ;;
            --verbose)
                verbose=1
                ;;
            --help)
                usage 0 "$0" ""
                ;;
            *)
                usage 1 "$0" "$opt"
                ;;
        esac
    done

    [[ "$rebuild" == 1 || "$clear" == 1 ]] && clean
    [[ "$test" == 1 ]] && coverage
    [[ "$debug" == 1 || "$release" == 0 || "$rebuild" == 1 ]] && debug "$verbose"
    [[ "$release" == 1 || "$rebuild" == 1 ]] && release "$verbose"
}

main $@
