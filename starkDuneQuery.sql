--Possibly relevant tables based on your question: ['erc20_ethereum.evt_transfer', 'erc20_ethereum.ERC20_evt_Transfer', 'erc20_ethereum.ERC20PresetMinterPauser_evt_Transfer', 'erc20_ethereum.evt_Transfer']
WITH transfers AS (
  SELECT
    "to" AS address,
    SUM(value) AS tokens
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x898BAD2774EB97cF6b94605677F43b41871410B1
    AND evt_block_number <= 15537393
    AND (
        "from" = 0x0000000000000000000000000000000000000000
        OR "from" = NULL
        OR "from" = 0x000000000000000000000000000000000000dEaD
        OR "from" = 0xe37E2a01feA778BC1717d72Bd9f018B6A6B241D5
        OR "from" = 0xdec2157831D6ABC3Ec328291119cc91B337272b5
        OR "from" = 0x16BEa2e63aDAdE5984298D53A4d4d9c09e278192
    ) AND NOT (
        "to" = 0xe37E2a01feA778BC1717d72Bd9f018B6A6B241D5
        OR "to" = 0xdec2157831D6ABC3Ec328291119cc91B337272b5
        OR "to" = 0x16BEa2e63aDAdE5984298D53A4d4d9c09e278192
    )
  GROUP BY
    "to"
  UNION ALL
  SELECT
    "from" AS address,
    -SUM(value) AS tokens
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = 0x898BAD2774EB97cF6b94605677F43b41871410B1
    AND evt_block_number <= 15537393
    AND (
        "to" = 0x0000000000000000000000000000000000000000
        OR "to" = NULL
        OR "to" = 0x000000000000000000000000000000000000dEaD
        OR "to" = 0xe37E2a01feA778BC1717d72Bd9f018B6A6B241D5
        OR "to" = 0xdec2157831D6ABC3Ec328291119cc91B337272b5
        OR "to" = 0x16BEa2e63aDAdE5984298D53A4d4d9c09e278192
    )
  GROUP BY
    "from"
), balances AS (
  SELECT
    address,
    SUM(tokens) AS balance
  FROM transfers
  GROUP BY
    address
  HAVING
    SUM(tokens) > 1000000000000000000
)
SELECT
address, balance
  --sum(balance)
FROM balances
ORDER BY balance desc
