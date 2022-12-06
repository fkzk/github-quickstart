#!/bin/bash
echo -e "\e[32m** 依存プログラムのチェック **\e[0m"
if $(type git >/dev/null 2>&1); then
    echo "Git: OK"
else
    echo "Git: インストールされていません"
fi
if $(type ssh >/dev/null 2>&1); then
    echo "SSH: OK"
else
    echo "SSH: インストールされていません"
fi

echo ""
echo -e "\e[32m** Gitの初期設定 **\e[0m"
if [ -z "$(git config --get user.name)" ]; then
    echo -n "Gitのユーザ名（英字フルネーム推奨）: "
    read git_user_name
    git config --global user.name "${git_user_name}"
    unset git_user_name
fi
if [ -z "$(git config --get user.email)" ]; then
    echo -n "Gitのメールアドレス: "
    read git_email
    git config --global user.name "${git_email}"
    unset git_email
fi
if [ -z "$(git config --get init.defaultBranch)" ]; then
    git config --global init.defaultBranch main
fi
if [ ! -d "$HOME/.ssh" ]; then
    mkdir "$HOME/.ssh"
fi
echo "user.name: $(git config --get user.name)"
echo "user.email: $(git config --get user.email)"
echo "init.defaultBranch: $(git config --get init.defaultBranch)"
    
echo ""
if $(ssh github 2>&1 | egrep -q "^Hi .+ You've successfully authenticated"); then
    echo -e "\e[36mすでにGitHubへのSSH接続の設定は完了しているようです。\e[0m"
    exit 0
fi
echo -e "\e[32m** SSH鍵の生成 **\e[0m"
if [ -f "$HOME/.ssh/github" ]; then
    echo "SSHの鍵（$HOME/.ssh/github）が存在するようです。"
    echo -n "使いたい鍵の名前（githubも可）: "
    read github_identity
    github_identity=${github_identity:-github}
    echo ""
else
    github_identity='github'
fi
    
echo ""
echo -e "\e[32m** SSH公開鍵をGitHubに登録 **\e[0m"
if [ ! -f "$HOME/.ssh/${github_identity}" ]; then
    ssh-keygen -t ed25519 -f "$HOME/.ssh/${github_identity}" -q -N ""
    if $(type clip >/dev/null 2>&1); then
        clip <"$HOME/.ssh/${github_identity}.pub"
        echo "公開鍵をクリップボードにコピーしました。"
    elif $(type pbcopy >/dev/null 2>&1); then
        pbcopy <"$HOME/.ssh/${github_identity}.pub"
        echo "公開鍵をクリップボードにコピーしました。"
    fi
    echo "https://github.com/settings/ssh/new にて公開鍵を登録しましょう。"
    echo "Titleには自分が使っているコンピュータを区別できる名前をつけましょう。"
    echo "[公開鍵]↓↓（この行は公開鍵ではない）"
    echo -ne "\e[33m"
    cat "$HOME/.ssh/${github_identity}.pub"
    echo -ne "\e[0m"
    echo "[公開鍵]↑↑（この行は公開鍵ではない）"
    echo -n "登録できたらEnterを押してください: "
    read registered
    unset registered
    echo ""
fi
    
echo ""
echo -e "\e[32m** SSH設定ファイルの確認 **\e[0m"
if [ -f "$HOME/.ssh/config" ]; then
    echo -e "\e[31m既存のSSH設定ファイル（$HOME/.ssh/config）が存在するようです。\e[0m"
    echo "対応方法は未実装"
    exit 1
else
    echo "Host github" >> "$HOME/.ssh/config"
    echo "    HostName github.com" >> "$HOME/.ssh/config"
    echo "    User git" >> "$HOME/.ssh/config"
    echo "    IdentityFile $HOME/.ssh/${github_identity}" >> "$HOME/.ssh/config"
fi

echo ""
echo -e "\e[32m** GitHubへの接続確認 **\e[0m"
if $(ssh github 2>&1 | egrep -q "^Hi .+ You've successfully authenticated"); then
    echo "GitHubへのSSH接続を確認しました。"
    echo -e "\e[36mgithub:/<ユーザ名>/<リポジトリ名>\e[0m によりリポジトリを指定できます。"
    echo ""
    echo "（例）$ git clone github:/fkzk/github-quickstart"
    echo ""
else
    echo -e "\e[31mGitHubへのSSH接続に失敗しました。\e[0m"
    echo "https://github.com/settings/keys を確認してください。"
    echo ""
fi