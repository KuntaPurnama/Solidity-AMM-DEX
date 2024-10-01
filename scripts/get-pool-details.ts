import { ethers } from "hardhat";
import { PoolFactoryAddress } from "../contractsAddress";

async function getPoolDetails(): Promise<void> {
    console.log("Get Pool Contract");
    const poolFactoryContract = await ethers.getContractAt("PoolFactory", PoolFactoryAddress);
    try {
        const poolDetails = await poolFactoryContract.getPoolDetails();
        console.log("Pool Details: ", poolDetails.toString());
    } catch (error) {
        console.error("Error fetching number of pools: ", error);
    }
}

getPoolDetails()
    .then(() => process.exit(0))
    .catch((error: Error) => {
        console.error(error);
        process.exit(1);
    });
