const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
    // 1. Get the signer (the account that will deploy the contract)
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 2. Define the initial Owner address. This is typically the deployer's address.
    const initialOwner = deployer.address;
    
    // 3. Get the Factory for the implementation contract
    const CritterHolesHammer = await ethers.getContractFactory("CritterHolesHammer");
    console.log("Deploying CritterHolesHammerUpgradeable (UUPS Proxy)...");

    // 4. Deploy the Proxy. 
    // `deployProxy` will:
    // a) Deploy the implementation contract (CritterHolesHammerUpgradeable).
    // b) Deploy the UUPS Proxy contract.
    // c) Call the `initialize(initialOwner)` function via the Proxy.
    const proxy = await upgrades.deployProxy(
        CritterHolesHammer, 
        [initialOwner], 
        { initializer: 'initialize', kind: 'uups' }
    );
    
    // Wait for the deployment transaction to be mined
    await proxy.waitForDeployment();

    const proxyAddress = await proxy.getAddress();
    console.log("✅ CritterHolesHammer Proxy deployed to:", proxyAddress);

    // Optional: Get the address of the underlying implementation contract
    const currentImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("   Implementation contract deployed to:", currentImplementationAddress);

    // 5. Verification (only applicable for networks with Block Explorers like Etherscan)
    try {
        if (["mainnet", "sepolia", "goerli", "polygon", "arbitrum", "optimism"].includes(hre.network.name)) {
            console.log("Waiting for block confirmations before verification...");
            // Wait for a minute to allow the Block Explorer to index the contract bytecode
            await new Promise(resolve => setTimeout(resolve, 60000)); 

            console.log("Verifying implementation contract...");
            await hre.run("verify:verify", {
                address: currentImplementationAddress,
            });
            console.log("✅ Implementation verified successfully.");
        }
    } catch (error) {
        console.error("Verification failed:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });