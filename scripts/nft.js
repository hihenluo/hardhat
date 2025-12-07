const { ethers } = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
    // 1. Get the signer (the account that will deploy the contract)
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // 2. Define the initial Owner address. This is typically the deployer's address.
    const initialOwner = deployer.address;
    
    // 3. Get the Factory for the implementation contract
    // NOTE: Pastikan nama kontrak di sini sesuai dengan nama di file Solidity Anda (CritterHolesHammerUpgradeable)
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
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });