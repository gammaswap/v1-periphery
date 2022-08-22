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

1. Follow instructions in v1-core readme to deploy locally.
2. Fill in the details in [scripts/deployCore.ts](scripts/deployCore.ts) from 
deploying v1-core logs.
3. Run ```npx hardhat --network localhost run scripts/deployCore.ts```.


Don't commit the secrets file.