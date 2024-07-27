import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("TREXFactory", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  await deploy("ClaimTopicsRegistry", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  await deploy("IdentityRegistry", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  await deploy("IdentityRegistryStorage", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  const claimTopicsRegistry = await deploy("ClaimTopicsRegistry", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  const modularCompliance = await deploy("ModularCompliance", {
    from: deployer,
    args: [claimTopicsRegistry.address], // Provide the required constructor argument here
    log: true,
    autoMine: true,
  });

  await deploy("TrustedIssuersRegistry", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  await deploy("SukukBond", {
    from: deployer,
    args: ["https://placeholder.uri/metadata/", modularCompliance.address],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract
  // const yourContract = await hre.ethers.getContract("YourContract", deployer);
};

export default deployContracts;

deployContracts.tags = [
  "TREXFactory",
  "Token",
  "ClaimTopicsRegistry",
  "IdentityRegistry",
  "IdentityRegistryStorage",
  "ModularCompliance",
  "TrustedIssuersRegistry",
  "SukukBond",
];
