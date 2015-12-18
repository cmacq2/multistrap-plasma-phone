#!/bin/sh

#
# A driver script for the various Makefile modules to provide useful defaults.
# This script is not meant to be executed directly (SRCDIR would be wrong).
# Instead a wrapper should be used that sources this script and calls
# run_driver_script.
#
# See run_driver_script (at end of file) for details.
#

display_help ()
{
    cat << EOF
Usage:
`basename $0` -h|--help
`basename $0` -t|--target <make-target...> [options]

-h, --help     display this help text

-t, --target   make the given 'make' target(s). Pass 'help' for help on the
               available targets and options.

EOF
}

display_default_options ()
{
    cat << EOF
The following directory variables are available to option arguments:

 * SRCDIR      : $SRCDIR
 * BUILDDIR    : $BUILDDIR
 * SCRIPT_DIR  : $SCRIPT_DIR
 * INVOKE_DIR  : $INVOKE_DIR

To refer to these variables you need to escape the dollar sign ($) to defer
variable expansionlike this: "SRCDIR=\\\$SRCDIR"

The full list of settings passed by default to 'make' is:

`iterate_default_options display_option`

EOF
}

append_to_make_options ()
{
    if [ -z "$MAKE_OPTIONS" ]
    then
        MAKE_OPTIONS="'$1'"
    else
        MAKE_OPTIONS="$MAKE_OPTIONS '$1'"
    fi
}

pass_to_make_options ()
{
    append_to_make_options "$1=$2"
}

display_option ()
{
    echo "$1=$2"
}

pass_option_kv ()
{
    option_name="`echo $1 | cut -c2-`"
    option_value="$(eval echo -n "$1")"
    if [ "x$option_value" != "x//" ]
    then
        case "$option_name" in
        special_arg_*)
            option_name="$(eval echo -n "$option_name" | cut -c13-)"
        ;;
        esac
        if [ -n "$2" ]
        then
            $2 "$option_name" "$option_value"
         fi
    fi
}

iterate_default_options ()
{
    for argname in $special_args
    do
        pass_option_kv "$argname" "$1"
    done
}

err_exit_delim ()
{
    if [ -z "$1" ]
    then
        DELIM="nothing"
    else
        DELIM="'$1'"
    fi
    exit_msg "$(cat <<EOD
run_driver_script: internal error detected in: '$0'.
Expected delimiter '--', got: $DELIM.
EOD
)" 255
}

err_exit_default_duplicate ()
{
    exit_msg "$(cat <<EOD
run_driver_script: internal error detected in: '$0'.
Duplicate default Make variable specified: $special_args_name.
Rejected: $1
Previous occurence: $special_args_name=$2
EOD
)" 255
    return 255
}

warn_duplicate ()
{
    cat <<EOD
`basename $0`: warning: duplicate Make variable specified: $special_args_name.
Ingored: $1
Previous occurence: $special_args_name=$2
EOD
    return 1
}

append_special_arg ()
{
    #
    # Track which default Make variables have been passed. This is quite ugly because:
    #
    # Need to 'namespace' the variables so we can distinguish from 'regular' vars:
    #   --> use prefix: special_arg_
    # The Make variable name is embedded in <name>=<value> syntax. Need to parse it:
    #   --> special_args_name, special_args_value_offset, special_args_value
    # Need to be able to recall each special_arg_*
    #   --> use special_args
    # Unfortunately the difference between empty/null values ("") and not set *is*
    # significant for Make so cannot rely on a simple if [ -z "$var" ] test:
    #   --> echo "$special_args" | grep -q to test if the variable was set in special_args
    # Need to avoid partial (substring) matches (foobar and foo)
    #   --> Use the $ sign as a signpost (need to escape -> \$)
    # Duplicate settings may be a sign of error (wrapper defaults) but equally, they may not:
    #   --> Apply the same logic to varname passed by reference in $1, except
    #       let callback in $2 decide how to handle duplicates and whether to continue.
    #
    special_args_name="$(eval echo "$3" | cut -d= -f1)"
    # determine length of name for use with cut later add + to get correct 1-based index
    special_args_name_value_offset="$(eval echo -n "+$special_args_name=" | wc -m)"
    special_args_value="$(eval echo "$3" | cut -c$special_args_name_value_offset-)"


    # Check for duplicate and bail if necessary.
    # If duplicates are an error $2 callback needs to terminate the script...
    echo "$(eval echo -n "\$$1")" | grep -q "\$special_arg_$special_args_name"

    if [ $? -eq 0 ]
    then
        $2 "$3" "$(eval echo -n "\$special_arg_$special_args_name")" || return $?
    else
        # namespace the Makefile varname
        special_args_name="special_arg_$special_args_name"
        if [ -z "$(eval echo -n "\$$1")" ]
        then
            eval "$1='\$$special_args_name'"
        else
            eval "$1='$special_args \$$special_args_name'"
        fi
    fi

    # avoid appending the same variable twice
    # this could happen if both defaults and program args contain the Make var
    echo "$special_args" | grep -q "\$$special_args_name"
    if [ ! $? -eq 0 ]
    then
        if [ -z "$special_args" ]
        then
            special_args="\$$special_args_name"
        else
            special_args="$special_args \$$special_args_name"
        fi
    fi
    eval "$special_args_name=\"$special_args_value\""
}

append_default_make_arg ()
{
    case "$1" in
    *=*)
        append_special_arg special_default_args err_exit_default_duplicate "$1"
    ;;
    --)
        return 1 # stop
    ;;
    *)
        #
        # $arg is set in run_driver_script, it will be one argument 'behind' the value of '$1'.
        # Effectively it allows to look back at the previous argument passed to this function.
        # Similarly, $last_arg will be another argument 'behind' ...
        #
        case "$arg" in
        -t|--target|-h|--help)
            err_exit_delim "$last_arg"
        ;;
        *)
            exit_msg "$(cat <<EOD
run_driver_script: internal error detected in: '$0'.
Expected delimiter '--' or <varname>=<value> syntax, got: '$last_arg' and '$1'.
EOD
)" 255
        ;;
        esac
    ;;
    esac
}

append_make_arg ()
{
    case "$1" in
    HELP_DESCRIPTION=*)
        echo "`basename $0`: warning: HELP_DESCRIPTION is a reserved option.\nIgnoring setting:\n$1"
        return 0 # return early to avoid appending to MAKE_OPTIONS
    ;;
    *=*)
        append_special_arg special_manual_args warn_duplicate "$1"
        return 0 # return early to avoid appending to MAKE_OPTIONS
    ;;
    build|buildinfo|clean|configure|help|rebuild|reconfigure)
        if [ -z "$MAKE_TARGETS" ]
        then
            MAKE_TARGETS="'$1'"
        else
            MAKE_TARGETS="$MAKE_OPTIONS '$1'"
        fi
        return 0 # return early to avoid appending to MAKE_OPTIONS
    ;;
    *)
        #
        # $arg is set in run_driver_script, it will be 'one' argument behind the value of '$1'.
        # Effectively it allows to look back at the previous argument passed to this function.
        #
        case "$arg" in
        -t|--target)
            exit_msg "Invalid target, got: '$1'." 254
        ;;
        *)
            exit_msg "Expected <varname>=<value> syntax, got: '$1'." 254
        ;;
        esac
    ;;
    esac

    if [ -z "$MAKE_OPTIONS" ]
    then
        MAKE_OPTIONS="'$1'"
    else
        MAKE_OPTIONS="$MAKE_OPTIONS '$1'"
    fi
}

exit_msg ()
{
    echo "$1"
    if [ "$2" != "255" ]
    then
        display_help
    fi
    if [ "$2" = "0" ]
    then
        display_default_options
    fi
    exit $2
}

set_default ()
{
    if [ -z "$(eval echo -n "\$special_arg_$1")" ]
    then
        if [ -z "$special_args" ]
        then
            special_args="\$special_arg_$1"
        else
            special_args="\$special_arg_$1 $special_args"
        fi
        eval "special_arg_$1=\"\$$1\""
    fi
}

default_help_desc ()
{
    case "$1" in
    multistrap)
        echo -n "generates Debian images using multistrap"
    ;;
    reprepro)
        echo -n "generates Debian repository using reprepro"
    ;;
    *)
        return 1
    ;;
    esac
}

#
# Main event: the driver script logic.
# Should be called from inside an appropriately named wrapper.
#
# Usage: run_driver_script <module> [caller_default_opts] -- "$@"
# Minimal example (wrapper):
# #!/bin/sh
# . /path/to/driver/driver.sh && run_driver_script reprepro -- "$@"
#
# An example (wrapper) set the SRCDIR default to $(pwd)/src directory:
# #!/bin/sh
# . /path/to/driver/driver.sh && run_driver_script multistrap SRCDIR="$(pwd)/src" -- "$@"
#
# module: required:
#    name of the module (directory with Makefile) which the driver script
#    provides a frontend for. The following modules are currently known:
#     * multistrap
#     * reprepro
#    run_driver_script will abort the script with an error if the module is
#    invalid (or missing).
# caller_default_opts: optional:
#    override default values for Makefile variables.
#    Use HELP_DESCRIPTION= to set a descriptive string of what the caller
#    'does' which is used in '--help' output.
#
#    The following directory variables are available:
#     * SRCDIR (run_driver_script default value for SRCDIR)
#     * BUILDDIR (run_driver_script default value for BUILDDIR)
#     * SCRIPT_DIR (directory in which the wrapper is located)
#     * INVOKE_DIR (directory from which the script was invoked, i.e. $(pwd))
#    To refer to these variables you need to escape the $ sign to defer
#    variable expansionlike this: "\$SRCDIR"
#
# --: required:
#    terminates caller_default_opts
#    run_driver_script will abort the script with an error if it is missing.
#
# $@: required:
#    program arguments supplied by the user to the caller script.
#
run_driver_script ()
{
    INVOKE_DIR="$(pwd)"
    SCRIPT_DIR="$(dirname "$0")"

    if [ -z "$SCRIPT_DIR" ]
    then
        SCRIPT_DIR="$INVOKE_DIR"
    else
        cd "$SCRIPT_DIR"
        SCRIPT_DIR="$(pwd)"
        cd "$INVOKE_DIR"
    fi
    DRIVER_MODULE="$1"
    BUILDDIR="$INVOKE_DIR"
    MAKE_OPTIONS=""
    MAKE_TARGETS=""
    DEFAULTS_CONSUMED=""
    HELP_DESCRIPTION="`default_help_desc $DRIVER_MODULE`" || exit_msg "run_driver_script: internal error detected in: '$0'.\nNo default help description available for: '$DRIVER_MODULE'." 255
    SRCDIR="$SCRIPT_DIR/$DRIVER_MODULE"
    shift 1
    last_arg=""
    arg=""

    for arg in "$@"
    do
        if [ -z "$DEFAULTS_CONSUMED" ]
        then
            append_default_make_arg "$1" && last_arg="$1" && shift 1
            if [ $? != 0 ]
            then
                if [ "$1" = "--" ]
                then
                    DEFAULTS_CONSUMED="true-fence"
                    shift 1
                else
                    exit_msg "run_driver_script: internal error detected in: '$0'.\nExpected delimiter '--', got: '$1'." 255
                fi
            fi
        fi
        if [ "$DEFAULTS_CONSUMED" = "true-fence" ]
        then
            set_default HELP_DESCRIPTION
            set_default SRCDIR
            set_default BUILDDIR
            case "$1" in
            -h|--help)
                exit_msg "`basename $0` : $HELP_DESCRIPTION" 0
            ;;
            -t|--target)
                shift 1
            ;;
            *)
                if [ -z "$1" ]
                then
                    exit_msg "A command is required." 254
                else
                    exit_msg "Unknown command: $1" 254
                fi
            ;;
            esac
            DEFAULTS_CONSUMED="true"
        elif [ -n "$1" -a "$DEFAULTS_CONSUMED" = "true" ]
        then
            append_make_arg "$1"
            shift 1
        fi
    done

    if [ -z "$DEFAULTS_CONSUMED" ]
    then
        err_exit_delim "$last_arg"
    fi

    if [ -z "$MAKE_TARGETS" ]
    then
        exit_msg "A <make-target> is required." 254
    else
        iterate_default_options pass_to_make_options
        eval make -f "'$SCRIPT_DIR/../$DRIVER_MODULE/Makefile'" $MAKE_OPTIONS $MAKE_TARGETS
        exit $?
    fi
}
