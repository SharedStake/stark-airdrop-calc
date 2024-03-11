// Starknet aidrop data 
// Sourced from dune analytics - see starkDuneQuery.sql for sql and link to ix query
// This script parses the data retrieved from dune to provide a breakdown of user 
// addr to stark airdrop amount based on veth2 total and strk alloc
// 1. Parse in csv, 
// 2. Gen total 
// 3. Gen allocation col according to veth2 share held
fs = require('fs')

FNAME = 'strkdrop.csv'
TOTAL_STARK_ALLOC = 360 * 500; // 360 strk per validator X 500 validators i.e 180k
OUTPUT_FILENAME='Stark_alloc.csv'

function parseCSVIn() {
    let accumulator = 0
    let data = fs.readFileSync(FNAME, 'utf8');
    let lines = data.split('\n')
    let address_to_stakedETH = {}
    lines.forEach(e => {
        let l = e.split(',')
        if (!isNaN(parseInt(l[3]))) {
        /** example row
         * 
            [
            '',
            '0x8f311b46b213759d106ecb4ecd024a3ee09d0895',
            '83936046096380762419',
            '1006853582554517134',
            '',
            '',
            '\r'
            ]
         */
            address_to_stakedETH[l[1]] = l[3]
            accumulator += parseInt(l[3])
        }
    });
    return {
        address_to_stakedETH: address_to_stakedETH,
        total: accumulator
    }
}

function genStarkAlloc(total, data) {
    let out = {};
    let accumulator_check = 0;
    Object.keys(data).forEach(addr => {
        let veth2 = data[addr];
        let proportion = (veth2/total) * TOTAL_STARK_ALLOC;
        out[addr] = proportion;
        accumulator_check += proportion;
    })
    return {
        address_to_strkAlloc: out,
        total: accumulator_check
    }
}

function genCSVOut(data) {
    let out = "Address,Stark Alloc";
    Object.keys(data).forEach(addr => {
        out = out.concat(`\n${addr},${data[addr]}`)
    })
    fs.writeFileSync(OUTPUT_FILENAME, out)
}

let data = parseCSVIn()
let parsed = genStarkAlloc(data.total, data.address_to_stakedETH)
if (parsed.total != TOTAL_STARK_ALLOC) {
    console.log(`Err: total doesnt match expected stark alloc - total: ${parsed.total} expected: ${total_strk_alloc}`)
    throw Error();
}
genCSVOut(parsed.address_to_strkAlloc)
