import { ethers } from "hardhat";

async function main() {
  const AddressProvider = await ethers.getContractFactory("AddressProvider");
  const addressProvider = await AddressProvider.deploy();
  await addressProvider.deployed();
  const addressProviderInstance = AddressProvider.attach(
    addressProvider.address,
  );
  console.log("AddressProvider Address: ", addressProvider.address);

  const ACL = await ethers.getContractFactory("ACL");
  const acl = await ACL.deploy();
  await acl.deployed();
  console.log("ACL Address: ", acl.address);
  await addressProviderInstance.setACL(acl.address, {});

  const ContractsRegister = await ethers.getContractFactory(
    "ContractsRegister",
  );
  const contractsRegister = await ContractsRegister.deploy(
    addressProvider.address,
  );
  await contractsRegister.deployed();
  console.log("ContractsRegister Address: ", contractsRegister.address);

  await addressProviderInstance.setContractsRegister(contractsRegister.address);

  const AccountFactory = await ethers.getContractFactory("AccountFactory");
  const accountFactory = await AccountFactory.deploy(addressProvider.address);
  await accountFactory.deployed();
  console.log("AccountFactory Address: ", accountFactory.address);
  addressProviderInstance.setAccountFactory(accountFactory.address);

  await addressProviderInstance.setWethToken(
    "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e",
  );

  const DataCompressor = await ethers.getContractFactory("DataCompressor");
  const dataCompressor = await DataCompressor.deploy(addressProvider.address);
  await dataCompressor.deployed();
  console.log("DataCompressor Address: ", dataCompressor.address);
  await addressProviderInstance.setDataCompressor(dataCompressor.address);

  const WETHGateway = await ethers.getContractFactory("WETHGateway");
  const wethGateway = await WETHGateway.deploy(addressProvider.address);
  await wethGateway.deployed();
  console.log("WETHGateway Address: ", wethGateway.address);
  await addressProviderInstance.setWETHGateway(wethGateway.address);

  const PriceOracle = await ethers.getContractFactory("PriceOracle");
  const priceOracle = await PriceOracle.deploy(addressProvider.address, []);
  await priceOracle.deployed();
  console.log("PriceOracle Address: ", priceOracle.address);
  await addressProviderInstance.setPriceOracle(priceOracle.address);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
