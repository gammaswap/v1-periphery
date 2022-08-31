# Steps to Run GammaSwap Tests Locally

1. Run ```npm install``` to install dependencies including hardhat.
2. Add secrets.json in the root folder with the following contents:
```
{
  "ALCHEMY_API_KEY": "<get account and key from https://www.alchemy.com/>",
  "GOERLI_ADDRESS": "<your wallet address here>",
  "GOERLI_PRIVATE_KEY": "<your private key here>"
}
```
You only need to fill in your address info.
3. Run ```npx hardhat test```

# Steps to Deploy To Contracts To Local Live Network

1. Run ```npx hardhat node``` the root folder in admin mode.
2. Open a new command prompt to the root folder in admin mode.
3. Run ```npx hardhat --network localhost run scripts/deploy.ts``` to deploy.

# Steps to Deploy To Contracts To Local Live Network with v1-core

1. Run ```npx hardhat node``` the root folder in admin mode.
2. Open a new command prompt to the root folder in admin mode.
3. Run ```npx hardhat --network localhost run scripts/deployPreCore.ts```.
4. Follow instructions in v1-core readme to deploy locally. You must copy an
address from the deployPreCore script to v1-core's deploy script.
5. Fill in the details in [scripts/deployPostCore.ts](scripts/deployPostCore.ts) 
from deploying v1-core logs.
6. Run ```npx hardhat --network localhost run scripts/deployPostCore.ts```.
7. Optional: run ```npx hardhat --network localhost run scripts/supplyEth.ts```
if you want to supply an outside wallet address. Enter the address into the
script.

Don't commit the secrets file.