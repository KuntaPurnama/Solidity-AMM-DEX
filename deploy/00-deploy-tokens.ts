import { ethers } from "hardhat";
import fs from "fs";

//don't forget import hardhat-deploy in hardhat.config.ts
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { developmentChains } from "../hardhat-helper-config";
import { network } from "hardhat";

import { verify } from "../utils/verify";

let contractAddresses = "";

const deployTokens: DeployFunction = async function ({
    getNamedAccounts,
    deployments
}: HardhatRuntimeEnvironment) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    const toWei = (num: number) => ethers.parseEther(num.toString());
    const isLocalNetwork: boolean = developmentChains.includes(network.name) ? true : false;

    //BNB
    await runDeployment("BNB", [toWei(100000000)], isLocalNetwork, deploy, log, deployer);

    //Chainlink
    await runDeployment("Chainlink", [toWei(200000000)], isLocalNetwork, deploy, log, deployer);

    //Polygon
    await runDeployment("Polygon", [toWei(500000000)], isLocalNetwork, deploy, log, deployer);

    //TRON
    await runDeployment("TRON", [toWei(1500000000)], isLocalNetwork, deploy, log, deployer);

    //WrappedBitcoin
    await runDeployment("WrappedBitcoin", [toWei(400000000)], isLocalNetwork, deploy, log, deployer);

    // Write contract addresses to a file
    fs.writeFileSync("./contractsAddress.ts", contractAddresses);
    console.log("Contract addresses saved to contractsAddress.ts");
};

async function runDeployment(
    contractName: string,
    args: any[],
    isLocalNetwork: boolean,
    deploy: (name: string, options: any) => Promise<any>,
    log: any,
    deployer: string
) {
    log(`---------------------Deploy ${contractName} --------------------\n`);
    const CONTRACT = await deploy(contractName, {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: isLocalNetwork ? 1 : 6
    });

    if (!isLocalNetwork) {
        await verify(CONTRACT.address, args);
    }

    contractAddresses += logDeployment(contractName, CONTRACT.address);
    log(`\n`);
}

function logDeployment(contractName: string, target: string): string {
    console.log(`${contractName} deployed to ${target}`);
    const log = `export const ${contractName}Address = '${target}';\n`;

    return log;
}

export default deployTokens;
deployTokens.tags = ["all", "tokens"];
