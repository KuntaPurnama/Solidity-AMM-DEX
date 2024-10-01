import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { developmentChains } from "../hardhat-helper-config";
import { network } from "hardhat";

import { verify } from "../utils/verify";
import fs from "fs";

const deployPool: DeployFunction = async function ({
    getNamedAccounts,
    deployments
}: HardhatRuntimeEnvironment) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    const isLocalNetwork: boolean = developmentChains.includes(network.name) ? true : false;

    //DEPLOY POOL FACTORY
    log(`---------------------Deploy PoolFactory --------------------`);
    const PoolFactoryContract = await deploy("PoolFactory", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: isLocalNetwork ? 1 : 6
    });

    if (!isLocalNetwork) {
        await verify(PoolFactoryContract.address, []);
    }

    const write = `export const PoolFactoryAddress = '${PoolFactoryContract.address}';`;
    const filePath = "./contractsAddress.ts";
    if (fs.existsSync(filePath)) {
        // If the file exists, append to it
        fs.appendFileSync(filePath, write);
    } else {
        // If the file doesn't exist, create and write to it
        fs.writeFileSync(filePath, write);
    }
    log(`---------------------Done--------------------`);
};

export default deployPool;
deployPool.tags = ["all", "pool"];
