#!/bin/bash

# Fund and spend an example "hashloop" SimplicityHL contract
# on Liquid Testnet.

# Dependencies: simc hal-simplicity jq curl

# This demo has been updated to not require the use of elements-cli.
# Some tasks could be simpler or more scalable in some sense if we used
# a local elements-cli, but here we use the Liquid Testnet web API
# instead to remove local dependencies. The main reason for this is that
# elementsd will require multiple gigabytes of blockchain data. Having
# a working local copy of elementsd can be useful for other development
# tasks, but represents a larger time and disk space commitment.

# The hashloop contract hashes bytes 0x00..0xff using a for_while loop,
# asserts the expected SHA-256 result, and then verifies a single BIP-340
# signature (witness::ALICE_SIGNATURE). Only 1 signer is needed
# (contrast with p2ms which required 2 of 3).

PROGRAM_SOURCE=./hashloop.simf
WITNESS_FILE=./hashloop.wit

# This is an unspendable public key address derived from BIP 0341.
INTERNAL_KEY="50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0"
TMPDIR=$(mktemp -d)

# Private key of the single party whose signature can approve this transaction.
PRIVKEY_1="0000000000000000000000000000000000000000000000000000000000000001"


# Some function definitions.

# Wait for user confirmation.
pause() { read -p "Press Enter to continue..."; echo; echo; }

# Find the unconfidential equivalent of a confidential Liquid address (or,
# if the provided address is already an unconfidential address, output it
# unchanged).
get_unconfidential(){
    if ! hal-simplicity address inspect "$1" | jq -e 'has("witness_pubkey_hash")' >/dev/null 2>&1; then
        echo "Not a valid Liquid address: $1" >&2
        exit 1
    fi

    if hal-simplicity address inspect "$1" | jq -e 'has("unconfidential")' >/dev/null 2>&1; then
        hal-simplicity address inspect "$1" | jq -r .unconfidential
    else
        echo "$1"
    fi
}

# Poll until tx $FAUCET_TRANSACTION is known on Liquid API endpoint $1.
# Note that .vout[0] data from the resulting JSON object is saved into
# $TMPDIR/faucet-tx-data.json to be used by other commands.
check_propagation(){
  # TODO: Give a useful error if this times out.
  echo -n "Checking for transaction $FAUCET_TRANSACTION via Liquid API..."
  for _ in {1..60}; do
    if curl -sSL "$1""$FAUCET_TRANSACTION" | jq ".vout[0]" 2>/dev/null | tee "$TMPDIR"/faucet-tx-data.json | jq -e >/dev/null 2>&1
  then
    echo " found."
    break
  else
    echo -n "."
  fi
  sleep 1
  done
}

# Show the values of specified environment variables.
show_vars() {
  for variable in "$@"; do
    echo -n "$variable="
    eval echo \$$variable
  done
}



# This script accepts a destination wallet address as a command-line argument
# ($1).  However, if none is provided, then we send the tLBTC coins back to
# the Liquid Faucet at its hard-coded return address.

if [ -z "$1" ]; then
    DESTINATION_ADDRESS=tlq1qq2g07nju42l0nlx0erqa3wsel2l8prnq96rlnhml262mcj7pe8w6ndvvyg237japt83z24m8gu4v3yfhaqvrqxydadc9scsmw
    echo "No destination address specified. Using Faucet refund address $DESTINATION_ADDRESS"
else
    DESTINATION_ADDRESS="$1"
    echo "Specified destination address is: $1"
fi

DESTINATION_ADDRESS=$(get_unconfidential "$DESTINATION_ADDRESS")
echo "Using unconfidential version of address: $DESTINATION_ADDRESS"
echo

show_vars PROGRAM_SOURCE WITNESS_FILE INTERNAL_KEY PRIVKEY_1 DESTINATION_ADDRESS

pause

# Compile program
echo simc "$PROGRAM_SOURCE"
simc "$PROGRAM_SOURCE"

pause

# Extract the compiled program from the output of that command
COMPILED_PROGRAM=$(simc "$PROGRAM_SOURCE" | sed '1d; 3,$d')

echo hal-simplicity simplicity info "$COMPILED_PROGRAM"
hal-simplicity simplicity info "$COMPILED_PROGRAM" | jq
CMR=$(hal-simplicity simplicity info "$COMPILED_PROGRAM" | jq -r .cmr)
CONTRACT_ADDRESS=$(hal-simplicity simplicity info "$COMPILED_PROGRAM" | jq -r .liquid_testnet_address_unconf)
echo

show_vars CMR CONTRACT_ADDRESS

pause

# Here we use a curl command to contact the Liquid Testnet faucet to
# ask it to fund our contract.
echo Running curl to connect to Liquid Testnet faucet...
FAUCET_TRANSACTION=$(curl "https://liquidtestnet.com/faucet?address=$CONTRACT_ADDRESS&action=lbtc" 2>/dev/null | sed -n "s/.*with transaction \([0-9a-f]*\)\..*$/\1/p")

show_vars FAUCET_TRANSACTION

pause

# Ask hal-simplicity to create a minimal PSET which asks to spend the
# value that the faucet sent to our contract, by sending it to
# DESTINATION_ADDRESS, less a fee.
echo hal-simplicity simplicity pset create '[ { "txid": "'"$FAUCET_TRANSACTION"'", "vout": 0 } ]' '[ { "'"$DESTINATION_ADDRESS"'": 0.00099900 }, { "fee": 0.00000100 } ]'
PSET1=$(hal-simplicity simplicity pset create '[ { "txid": "'"$FAUCET_TRANSACTION"'", "vout": 0 } ]' '[ { "'"$DESTINATION_ADDRESS"'": 0.00099900 }, { "fee": 0.00000100 } ]' | jq -r .pset)

echo "Minimal PSET is $PSET1"

pause

echo "Looking up faucet transaction details."

check_propagation https://liquid.network/liquidtestnet/api/tx/
cat "$TMPDIR"/faucet-tx-data.json | jq

HEX=$(jq -r .scriptpubkey < "$TMPDIR"/faucet-tx-data.json)
ASSET=$(jq -r .asset < "$TMPDIR"/faucet-tx-data.json)
VALUE=0.00$(jq -r .value < "$TMPDIR"/faucet-tx-data.json)

echo "Extracted hex:asset:value parameters $HEX:$ASSET:$VALUE"

pause

echo hal-simplicity simplicity pset update-input "$PSET1" 0 -i "$HEX:$ASSET:$VALUE" -c "$CMR" -p "$INTERNAL_KEY"
hal-simplicity simplicity pset update-input "$PSET1" 0 -i "$HEX:$ASSET:$VALUE" -c "$CMR" -p "$INTERNAL_KEY" | tee "$TMPDIR"/updated.json | jq

PSET2=$(cat "$TMPDIR"/updated.json | jq -r .pset)

pause

# Signature for the single required signer (witness::ALICE_SIGNATURE).
echo "Signing on behalf of Alice using private key $PRIVKEY_1"
echo hal-simplicity simplicity sighash "$PSET2" 0 "$CMR" -x "$PRIVKEY_1"
hal-simplicity simplicity sighash "$PSET2" 0 "$CMR" -x "$PRIVKEY_1" | jq
SIGNATURE_1=$(hal-simplicity simplicity sighash "$PSET2" 0 "$CMR" -x "$PRIVKEY_1" | jq -r .signature)
echo "Alice's signature is $SIGNATURE_1 (different from JSON due to signing nonce)"

# Put the signature into the appropriate place in the .wit file
echo "Copying signature into copy of witness file $WITNESS_FILE..."
cp "$WITNESS_FILE" "$TMPDIR"/witness.wit
sed -i "s/\"value\": \"0x[0-9a-f]*/\"value\": \"0x$SIGNATURE_1/" "$TMPDIR"/witness.wit

echo "Contents of witness:"
cat "$TMPDIR"/witness.wit

pause

# Recompile with the populated witness file so the signature is embedded.
echo "Recompiling Simplicity program with attached populated witness file..."
echo simc "$PROGRAM_SOURCE" -w "$TMPDIR"/witness.wit
simc "$PROGRAM_SOURCE" -w "$TMPDIR"/witness.wit | tee "$TMPDIR"/compiled-with-witness

# Maybe simc should also output structured data like JSON!
PROGRAM=$(cat "$TMPDIR"/compiled-with-witness | sed '1d; 3,$d')
WITNESS=$(cat "$TMPDIR"/compiled-with-witness | sed '1,3d; 5,$d')

pause

echo hal-simplicity simplicity pset finalize "$PSET2" 0 "$PROGRAM" "$WITNESS"
hal-simplicity simplicity pset finalize "$PSET2" 0 "$PROGRAM" "$WITNESS" | jq
PSET3=$(hal-simplicity simplicity pset finalize "$PSET2" 0 "$PROGRAM" "$WITNESS" | jq -r .pset)

pause

echo hal-simplicity simplicity pset extract "$PSET3"
hal-simplicity simplicity pset extract "$PSET3" | jq
RAW_TX=$(hal-simplicity simplicity pset extract "$PSET3" | jq -r)

echo "Raw transaction is $RAW_TX"

pause

check_propagation https://blockstream.info/liquidtestnet/api/tx/

echo "Submitting raw transaction via Liquid Testnet web API..."
echo -n "Resulting transaction ID is "
TXID=$(curl -X POST "https://blockstream.info/liquidtestnet/api/tx" -d "$RAW_TX" 2>/dev/null)
echo "$TXID"
echo
echo "You can view it online at https://blockstream.info/liquidtestnet/tx/$TXID?expand"

echo
