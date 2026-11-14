#!/usr/bin/env bash

# Copyright (C) David P. Callanan 2026. All rights reserved.

set -euo pipefail

err() {
  echo "$@" >&2
}

find_root() {
  local d="$PWD"
  while true; do
    if [ -d "$d/.gitlayer" ]; then
      echo "$d"
      return 0
    fi
    local parent
    parent="$(dirname "$d")"
    if [ "$parent" = "$d" ]; then
      break
    fi
    d="$parent"
  done

  git rev-parse --show-toplevel 2>/dev/null || true
}

ensure_gitlayer() {
  local root="$1"
  mkdir -p "$root/.gitlayer"

  local gi="$root/.git/info/exclude"
  touch "$gi"

  if grep -qxF "#-- /.gitlayer/" "$gi"; then
    return 0
  fi
  if grep -qxF "/.gitlayer/" "$gi"; then
    return 0
  fi
  echo "# (auto) disable with '#-- ' prefix" >> "$gi"
  echo "/.gitlayer/" >> "$gi"
}

is_alpha() {
  [[ "$1" =~ ^[A-Za-z]+$ ]]
}

layer_git_dir() {
  local root="$1"
  local name="$2"
  if [ "$name" = "(default)" ]; then
    echo "$root/.git"
  else
    echo "$root/.gitlayer/$name/.git"
  fi
}

cmd_switch() {
  local root="$1"
  shift
  local copy_src=""
  local name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --copy)
        shift
        if [ $# -eq 0 ]; then
          err "gl: --copy requires an argument"
          exit 1
        fi
        copy_src="$1"
        ;;
      *)
        if [ -z "$name" ]; then
          name="$1"
        else
          err "gl: unexpected argument '$1'"
          exit 1
        fi
        ;;
    esac
    shift
  done

  if [ -z "$name" ]; then
    err "gl: switched to default .git"
    return 0
  fi

  if ! is_alpha "$name"; then
    err "gl: layer name must be alpha-only"
    exit 1
  fi

  local layer_dir="$root/.gitlayer/$name"
  local git_dir="$layer_dir/.git"

  if [ ! -d "$git_dir" ]; then
    if [ -n "$copy_src" ]; then
      if [ "$copy_src" != "(default)" ] && ! is_alpha "$copy_src"; then
        err "gl: --copy source must be alpha-only or (default)"
        exit 1
      fi

      local src_git
      src_git="$(layer_git_dir "$root" "$copy_src")"

      if [ ! -d "$src_git" ]; then
        err "gl: copy source '$copy_src' not found"
        exit 1
      fi

      mkdir -p "$layer_dir"
      cp -r "$src_git" "$git_dir"
      err "gl: created layer '$name' as copy of '$copy_src'"
    else
      mkdir -p "$layer_dir"
      git --git-dir="$git_dir" init -q
      err "gl: created new empty layer '$name'"
    fi

    mkdir -p "$git_dir/info"
    touch "$git_dir/info/exclude"
    if ! grep -qxF "/.gitlayer/" "$git_dir/info/exclude" \
        && ! grep -qxF "#-- /.gitlayer/" "$git_dir/info/exclude"; then
      echo "# (auto) disable with '#-- ' prefix" >> "$git_dir/info/exclude"
      echo "/.gitlayer/" >> "$git_dir/info/exclude"
    fi
  fi

  echo "export GIT_DIR=\"$git_dir\""
  echo "export GIT_WORK_TREE=\"$root\""
  err "gl: switched to layer '$name'"
  emitted_env=1
}

cmd_rm() {
  local root="$1"
  local name="${2:-}"

  if [ -z "$name" ]; then
    err "gl: usage: gl rm <layer_name>"
    exit 1
  fi

  local layer_dir="$root/.gitlayer/$name"
  if [ ! -d "$layer_dir" ]; then
    err "gl: layer '$name' does not exist"
    exit 1
  fi

  rm -rf "$layer_dir"
  err "gl: removed layer '$name'"
}

cmd_wipe() {
  local root="$1"
  local gl_dir="$root/.gitlayer"

  read -r -p "gl: this will delete ALL layers under $gl_dir. Type 'yes' to confirm: " confirm

  if [ "$confirm" = "yes" ]; then
    rm -rf "$gl_dir"
    err "gl: wiped .gitlayer"
  else
    err "gl: aborted"
  fi
}

main() {
  local root
  root="$(find_root)"

  if [ -z "$root" ]; then
    err "gl: not inside a git repo"
    exit 1
  fi

  ensure_gitlayer "$root"

  echo "unset GIT_DIR GIT_WORK_TREE"

  if [ $# -eq 0 ]; then
    err "gl: env refreshed (root=$root)"
    return 0
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    s|switch)
      cmd_switch "$root" "$@"
      ;;
    rm)
      cmd_rm "$root" "$@"
      ;;
    wipe)
      cmd_wipe "$root"
      ;;
    *)
      err "gl: unknown command '$cmd'"
      err "usage: gl s [name] [--copy <layer|(default)>] | gl rm <name> | gl wipe"
      exit 1
      ;;
  esac
}

main "$@"
