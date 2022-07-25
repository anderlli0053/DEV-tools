#!/usr/bin/env bash
# set -euxo pipefail

current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
DATE=$(TZ=UTC-8 date '+%Y-%m-%d %H:%M:%S')
commiter=$(git config user.name)
bucket_dir="${current_dir}/bucket/"
readme_file="${current_dir}/README.md"
toc_file="${current_dir}/toc.md"
table_start="<\!--ts-->"
table_end="<\!--te-->"
bucket_repo="https://github.com/Ryanjiena/Meta"

sysinternals=(accesschk accessenum adexplorer adinsight adrestore autologon autoruns bginfo bluescreen cacheset clockres contig coreinfo ctrl2cap debugview desktops disk2vhd diskext diskmon diskview du efsdump findlinks handle hex2dec junction ldmdump listdlls livekd loadorder logonsessions movefile notmyfault ntfsinfo pagedefrag pendmoves pipelist portmon procdump processexplorer processmonitor psexec psfile psgetsid psinfo pskill pslist psloggedon psloglist pspasswd psping psservice psshutdown pssuspend rammap rdcman regdelnull reghide regjump ru sdelete shareenum shellrunas sigcheck streams strings sync sysmon tcpview vmmap volumeid whois winobj zoomit)

# manifest info generator
function manifest_info_generator() {
    local manifest_file=$(basename "$1")
    local manifest_name=$(basename "$1" .json)
    local manifest_raw="${bucket_repo}/blob/master/bucket/${manifest_file}"
    local manifest_version=$(cat "$1" | jq -r '.version')
    local manifest_desc=$(cat "$1" | jq -r '.description')
    local manifest_homepage=$(cat "$1" | jq -r '.homepage')
    local manifest_committer_date=$(git log -1 --pretty=format:%cd --relative-date "$1")
    local manifest_committer_hash=$(git log -1 --pretty=format:%H "$1")
    local manifest_committer_diff_url="${bucket_repo}/commit/${manifest_committer_hash}"
    local basename_without_extension=$(basename "$1" .json)
    echo -e "\n| [${manifest_name}](${manifest_homepage}) | [${manifest_version}](${manifest_raw}) | [${manifest_committer_date}](${manifest_committer_diff_url}) | ${manifest_desc} |"
    return $?
}

# table generator
function table_generator() {
    cd ${bucket_dir}
    manifest_table_header="| Name | Version | Commit | Description |\n|:---|:---|:---|:---|"
    # manifest_table_body=$(find . -name '*.json' -printf "'%f'\n" | xargs -I {} bash -c 'manifest_info_generator "$@"' {})
    manifest_table_body=""
    manifest_table_footer="\n\n\n*Updated by: ${commiter}, at: ${DATE}*"
    for manifest in $(find . -name '*.json' | sort -f); do
        manifest_table_body="${manifest_table_body}$(manifest_info_generator "${manifest}")"
    done
    echo -e "${manifest_table_header}${manifest_table_body}${manifest_table_footer}"
}

# insert table into README.md
function insert_table() {
    # clear old table
    # http://fahdshariff.blogspot.ru/2012/12/sed-mutli-line-replacement-between-two.html
    sed -i "/${table_start}/,/${table_end}/{//!d;}" "${readme_file}"

    # insert new table
    table_generator >"${toc_file}"
    sed -i "/${table_start}/r ${toc_file}" "${readme_file}"

    # clean
    rm -f "${toc_file}"
}

# sudo apt install -y git jq sed
# table_generator
insert_table
