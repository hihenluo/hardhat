const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
    // 1. Get the deployer account signer
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 2. Set the initial owner (usually the deployer)
    const initialOwner = deployer.address;
    
    // 3. Get the Contract Factory for the implementation contract
    // NOTE: This name must EXACTLY match the contract name in your Solidity file.
    const CritterHolesHammer = await ethers.getContractFactory("CritterHolesHammer"); 
    console.log("Deploying CritterHolesHammer (Transparent Proxy)...");

    // 4. Deploy the Proxy.
    // We use 'transparent' kind here. This deploys three contracts:
    // a) The Implementation Contract (CritterHolesHammerTransparent)
    // b) The Admin contract
    // c) The Transparent Proxy contract
    const proxy = await upgrades.deployProxy(
        CritterHolesHammer, 
        // Arguments for the initialize function: initialize(address _initialOwner)
        [initialOwner], 
        { 
            initializer: 'initialize', 
            kind: 'transparent' 
        }
    );
    
    // Wait for the deployment transaction to be mined
    await proxy.waitForDeployment();

    const proxyAddress = await proxy.getAddress();
    console.log("✅ CritterHolesHammer Proxy deployed to:", proxyAddress);

    // Get the address of the actual logic contract (implementation)
    const currentImplementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("   Implementation contract deployed to:", currentImplementationAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        // Handle any errors during deployment
        console.error(error);
        process.exit(1);
    });