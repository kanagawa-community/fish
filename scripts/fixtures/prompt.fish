# Prompt and helpers used only to render the preview images.
set -g fish_prompt_pwd_dir_length 0
function fish_prompt
    set_color $fish_color_user
    printf kanagawa
    set_color $fish_color_normal
    printf @
    set_color $fish_color_host
    printf %s $PREVIEW_VARIANT
    set_color $fish_color_normal
    printf ' '
    set_color $fish_color_cwd
    printf %s (prompt_pwd)
    set_color $fish_color_normal
    printf '\n❯ '
end
function fish_right_prompt
end
function fish_greeting
end
