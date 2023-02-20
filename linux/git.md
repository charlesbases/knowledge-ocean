## 1. tag

- ##### 添加

  ```shell
  # new tag
  git tag -a "v1.0.0" -m "release v1.0.0"
  
  # push
  git push --tags
  
  #
  v=v1.0.0; git tag -a "$v" -m "release $v" && git push --tags
  ```

- ##### 删除

  ```shell
  # 删除本地
  git tag -d v1.0.0
  
  # 删除远程
  git push origin :refs/tags/v1.0.0
  
  #
  v=v1.0.0; git tag -d $v && git push origin :refs/tags/$v	
  ```

--------

## 2. pull

```shell

```

--------

## 3. push

```shell
# 推送到远程分支
git push origin <local-branch>:<remote-branch>
```

--------

## 2. branch

```shell
# 分支关联
git branch --set-upstream-to=<remote-branch> <local-branch>
```

- ##### 删除

  ```shell
  # 本地分支
  git branch -d branch
  
  # 远程分支
  git push origin -d branch
  
  #
  b=branch; git push origin --delete $b && git branch -d $b
  ```

--------

## 3. submodule

- ##### 添加

  ```shell
  git submodule add url [path/module]
  ```

- ##### 删除

  ```shell
  # 删除 git 缓存
  git rm --cached [module]
  
  # 删除 .gitmodules 子模块信息
  [submodule "module"]
  
  # 删除 .git/config 子模块信息
  [submodule "module"]
  
  # 删除 .git 子模块文件
  rm -rf .git/modules/[model]
  ```

--------

## 4. gitconfig

```yaml
[user]
    name = zhiming.sun
    email = zhiming.sun@qq.com

[pull]
    rebase = true

[push]
    default = current

[core]
    editor = vim
    autocrlf = input
    excludesfile = ~/.gitignore

[color]
    ui = auto

[color.branch]
    current = blue
    local   = green
    remote  = red

[color.status]
    added     = green
    changed   = blue
    untracked = red

[http]
    postBuffer = 1m
    sslVerify  = false

[alias]
    logs = log --graph --abbrev-commit --decorate --oneline --date=format:'%Y-%m-%d %H:%M:%S' --format=format:'%>>|(10,trunc)% %C(bold red)%h%Creset %C(cyan)%ad%Creset %C(green)[%<(9)%ar]%Creset  %C(dim white)%an%Creset %C(yellow)%d%Creset%n %>>|(9.5)% %C(white)%s%Creset ' --all
    trace = update-index --assume-unchanged
    untrace = update-index --no-assume-unchanged

[branch]
    autosetuprebase = always

[credential]
    helper = store
    # mac
    # helper = osxkeychain
```

--------

## 5. git-for-windows

```shell
# inputrc
sed -i -s 's/set bell-style visible/set bell-style none/g' inputrc

# vimrc

# profile.d
cat > "profile.d\git-prompt.sh" << EOF
if test -f /etc/profile.d/git-sdk.sh
then
	TITLEPREFIX=SDK-${MSYSTEM#MINGW}
else
	TITLEPREFIX=$MSYSTEM
fi

if test -f ~/.config/git/git-prompt.sh
then
	. ~/.config/git/git-prompt.sh
else
	PS1='\[\033]0;$TITLEPREFIX:$PWD\007\]' # set window title
	PS1="$PS1"'\n'                     # new line

	PS1="$PS1"'\033[34m'               # change color
	PS1="$PS1"'# '                     #
	PS1="$PS1"'\033[0m'                # reset color

	PS1="$PS1"'\033[36m'               # change color
	PS1="$PS1"'\u '					   # user
	PS1="$PS1"'\033[0m'                # reset color

	PS1="$PS1"'@ '                     #

	PS1="$PS1"'\033[32m'               # change color
	PS1="$PS1"'charlesbases '          # user
	PS1="$PS1"'\033[0m'                # reset color

	PS1="$PS1"'in '

	PS1="$PS1"'\033[33m'               # change color
	PS1="$PS1"'\w '                    # pwd
	PS1="$PS1"'\033[0m'                # reset color

	PS1="$PS1"'[\t]'

	if test -z "$WINELOADERNOEXEC"
	then
		GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
		COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
		COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
		COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
		if test -f "$COMPLETION_PATH/git-prompt.sh"
		then
			. "$COMPLETION_PATH/git-completion.bash"
			. "$COMPLETION_PATH/git-prompt.sh"
			PS1="$PS1"'\[\033[36m\]'  # change color to cyan
			PS1="$PS1"'`__git_ps1`'   # bash function
		fi
	fi
	PS1="$PS1"'\[\033[0m\]'        # change color
	PS1="$PS1"'\n'                 # new line
	PS1="$PS1"'\033[31m\$\033[0m '                 # prompt: always $
fi

MSYS2_PS1="$PS1"               # for detection by MSYS2 SDK's bash.basrc

# Evaluate all user-specific Bash completion scripts (if any)
if test -z "$WINELOADERNOEXEC"
then
	for c in "$HOME"/bash_completion.d/*.bash
	do
		# Handle absence of any scripts (or the folder) gracefully
		test ! -f "$c" ||
		. "$c"
	done
fi

EOF
```

