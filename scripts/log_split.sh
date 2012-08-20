#!/usr/bin/env bash

log_base=${1:?}
log_max=${2:-10000}
log_bak_max=${3:-4}

line=0
log_num=0
rm -f $log_base
while read i; do
    if (( line >= log_max )); then
        let line=0
        let log_num=log_bak_max-1
        while (( log_num >= 1 )); do
            let log_prev=log_num-1
            if (( log_num >=  2 )); then
                [ -f $log_base.$log_prev ] && mv $log_base.$log_prev $log_base.$log_num
            else
                [ -f $log_base ] && mv $log_base $log_base.1
            fi
            let log_num=log_num-1
        done
        rm -f $log_base
    fi
    let line=line+1
    echo "$i" >>$log_base
done


