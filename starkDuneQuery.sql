/* 
interactive dune query here: https://dune.com/queries/3499440/5884783/
saved here for posterity and review
 */ 

 SELECT sgt.address AS sgt_addr, sgt.balance AS sgt_bal, veth2.address AS veth2_addr, veth2.balance AS veth2_bal
FROM (
  WITH transfers AS (
  /* we count all users who minted veth2 withot discounting ALL sends to include users staking in contracts */
  /* we only subtract sends for users who sent to the 0 address and exited via a burn */
  SELECT
  "from",
    NULL AS "to",
    -SUM(value) AS value
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x898BAD2774EB97cF6b94605677F43b41871410B1
    AND (
        "to" = 0x0000000000000000000000000000000000000000
        OR "to" = NULL
        OR "to" = 0x000000000000000000000000000000000000dEaD
    )
    AND evt_block_number <= 15537393 -- https://www.investopedia.com/ethereum-completes-the-merge-6666337#:~:text=Key%20Takeaways,1%3A42%3A42%20EST.
  GROUP BY
    "from"
  UNION ALL
  
  SELECT
    NULL AS "from",
    "to",
    SUM(value) AS value
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x898BAD2774EB97cF6b94605677F43b41871410B1
    AND evt_block_number <= 15537393
  GROUP BY
    "to"
), balances AS (
  SELECT
    COALESCE("from", "to") AS address,
    SUM(value) AS balance
  FROM transfers
  GROUP BY
    COALESCE("from", "to")
)
SELECT
  address,
  balance
FROM balances) AS veth2,
--Possibly relevant tables based on your question: ['tokens.balances', 'erc20_ethereum.evt_Transfer', 'erc20.evt_Transfer', 'erc20_ethereum.ERC20_evt_Transfer']
(WITH transfers AS (
  SELECT
    "from" AS address,
    -SUM(value) AS amount
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x24c19f7101c1731b85f1127eaa0407732e36ecdd
  GROUP BY
    "from"
  UNION ALL
  SELECT
    "to" AS address,
    SUM(value) AS amount
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x24c19f7101c1731b85f1127eaa0407732e36ecdd
  GROUP BY
    "to"
), balances AS (
  SELECT
    address,
    SUM(amount) AS balance
  FROM transfers
  GROUP BY
    address
  HAVING
    SUM(amount) > 0
 ) SELECT
  address,
  balance
FROM balances
) as SGT
WHERE
  sgt.balance > 0 AND veth2.balance > 0 AND sgt.address = veth2.address
ORDER BY
  veth2.balance DESC
