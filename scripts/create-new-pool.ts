import { ethers } from "hardhat";
import { PoolFactoryAddress, BNBAddress, ChainlinkAddress } from "../contractsAddress";

async function createPool(): Promise<void> {
    console.log("Get Pool Contract");
    const [signer] = await ethers.getSigners();
    const poolFactoryContract = await ethers.getContractAt("PoolFactory", PoolFactoryAddress, signer);

    console.log("Create New Pool");
    const createPoolTx = await poolFactoryContract.createPool(BNBAddress, ChainlinkAddress, 30);
    await createPoolTx.wait();
}

createPool()
    .then(() => process.exit(0))
    .catch((error: Error) => {
        console.error(error);
        process.exit(1);
    });
