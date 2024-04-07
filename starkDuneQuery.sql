SELECT veth2.address, veth2.balance AS veth2_bal
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
    AND NOT (
        "to" = 0x0000000000000000000000000000000000000000
        OR "to" = 0x000000000000000000000000000000000000dEaD
        OR "to" = 0xe37E2a01feA778BC1717d72Bd9f018B6A6B241D5
        OR "to" = 0xdec2157831D6ABC3Ec328291119cc91B337272b5
        OR "to" = 0x16BEa2e63aDAdE5984298D53A4d4d9c09e278192
        OR "to" = 0xa919d7a5fb7ad4ab6f2aae82b6f39d181a027d35 --staking pod
        or "to" = 0x2b228842b97ab8a1f3dcd216ec5d553ada957915 -- rewards
    )
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
FROM balances where balance > 100000000000000000
) AS veth2
--Possibly relevant tables based on your question: ['tokens.balances', 'erc20_ethereum.evt_Transfer', 'erc20.evt_Transfer', 'erc20_ethereum.ERC20_evt_Transfer']
WHERE
  veth2.balance > 0
ORDER BY
  veth2.balance DESC,
  veth2.address
