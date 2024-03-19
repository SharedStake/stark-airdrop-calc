// Starknet aidrop data 
// Sourced from dune analytics - see starkDuneQuery.sql for sql and link to ix query
// This script parses the data retrieved from dune to provide a breakdown of user 
// addr to stark airdrop amount based on veth2 total and strk alloc
// 1. Parse in csv, 
// 2. Gen total 
// 3. Gen allocation col according to veth2 share held
fs = require('fs')

FNAME = 'veth2.csv'
TOTAL_STARK_ALLOC = 360 * 500; // 360 strk per validator X 500 validators i.e 180k
OUTPUT_FILENAME='Stark_alloc2.csv'
ETH_PER_VALIDATOR = 32;
mainnet_indices = require('./indices.json')
mainnet_indices = mainnet_indices.sort((a, b) => a - b)

function parseCSVIn(pos1 = 0, pos2 = 3) {
    let accumulator = 0
    let data = fs.readFileSync(FNAME, 'utf8');
    let lines = data.split('\n')
    let address_to_stakedETH = {}
    lines.forEach(e => {
        let l = e.split(',')
        if (!isNaN(parseInt(l[pos2]))) {
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
            address_to_stakedETH[l[pos1]] = l[pos2]
            accumulator += parseInt(l[pos2])
        }
    });
    return {
        address_to_stakedETH: address_to_stakedETH,
        total: accumulator
    }
}

function genRate(data) {
    // coalesce total veth2 staked by valid users into 500 validators 

    let accumulator_eth = 0;
    Object.keys(data).forEach(addr => {
        accumulator_eth += data[addr]/1e18;
    })
    let rate = (500*32)/accumulator_eth;
    console.log('Total veth2: ', accumulator_eth)
    console.log('Rate: ', rate)
    return (rate);
}

function genStarkAlloc(total, data) {
    let out = {};
    let accumulator_check = 0;
    let accumulator_eth = 0;
    let mainnet_index = 0;
    // let rate = genRate(data);
    let rate = 1;
    let curI;
    Object.keys(data).forEach(addr => {
        let veth2_user = data[addr];
        let proportion = (veth2_user/total) * TOTAL_STARK_ALLOC;
        accumulator_eth += veth2_user / 1e18;
        curI = Math.floor(accumulator_eth / ETH_PER_VALIDATOR);
        let indices = Math.floor((veth2_user/1e18) / ETH_PER_VALIDATOR);
        let indices_validator = [];
        if (indices > 1) {
            for (let i = 0; i < indices; i++) {
                const element = mainnet_indices[mainnet_index];
                indices_validator.push(element);
                if (curI > mainnet_index && mainnet_index < 500) mainnet_index++;
            }
        } else {
            indices_validator.push(mainnet_indices[mainnet_index])
            if (mainnet_index < curI && mainnet_index<499) mainnet_index++;
        }
        out[addr] = {
            stark_alloc: proportion,
            indices: indices_validator
        };
        accumulator_check += proportion;
    })
    console.log(`Total included mainnet indices: ${mainnet_index+1}`)
    console.log(`Total included mainnet eth: ${accumulator_eth}`)
    console.log(`Error margin: ETH total: ${((accumulator_eth-16000)/16000)*100}% | Validator Count: ${((curI-499)/499)*100}%`)

    return {
        address_to_strkAlloc: out,
        total: accumulator_check
    }
}

function genCSVOut(data) {
    let out = "Address,Mainnet Indices,Stark Alloc";
    Object.keys(data).forEach(addr => {
        out = out.concat(`\n${addr},[${data[addr].indices.join('.')}],${data[addr].stark_alloc}`)
    })
    fs.writeFileSync(OUTPUT_FILENAME, out)
}

let data = parseCSVIn(0, 1)
let parsed = genStarkAlloc(data.total, data.address_to_stakedETH)
if (Math.round(parsed.total) != TOTAL_STARK_ALLOC) {
    console.log(`Err: total doesnt match expected stark alloc - total: ${parsed.total} expected: ${TOTAL_STARK_ALLOC}`)
    throw Error();
}
genCSVOut(parsed.address_to_strkAlloc)

