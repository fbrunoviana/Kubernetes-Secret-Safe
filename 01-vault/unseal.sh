#!/bin/bash


KEYS=$(jq -r '@sh "\(.unseal_keys_hex)\n"'< $1)
echo $KEYS

for KEY in $KEYS
do
  echo $KEY
  KEY2=$(echo -n $KEY | cut -d "'" -f 2)
  kubectl exec -i vault-0 -n vault - -- vault operator unseal $KEY2
done

kubectl -n vault exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
for KEY in $KEYS
do
  echo $KEY
  KEY2=$(echo -n $KEY | cut -d "'" -f 2)
  kubectl exec -i vault-1 -n vault - -- vault operator unseal $KEY2
done

kubectl -n vault exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
for KEY in $KEYS
do
  echo $KEY
  KEY2=$(echo -n $KEY | cut -d "'" -f 2)
  kubectl exec -i vault-2 -n vault - -- vault operator unseal $KEY2
done