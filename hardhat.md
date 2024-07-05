async function main() {
const [deployer] = await ethers.getSigners();
console.log("main ~ deployer address:", deployer.address);
const USDTxntu = await ethers.getContractFactory("USDTxntu");
const myContract = await USDTxntu.deploy(stakingTokenAdd);
const myContractAdd = await myContract.getAddress();
console.log("MyContract deployed to:", myContractAdd);
// const ZentuStaking = await ethers.getContractFactory("ZentuStaking");
// const zentuStaking = await upgrades.deployProxy(ZentuStaking, [
// stakingTokenAdd,
// rewardTokenAdd,
// ]);
// await zentuStaking.waitForDeployment();
// const zentuStakingAdd = await zentuStaking.getAddress();
// console.log("zentuStaking contract address:", zentuStakingAdd);

// ================== UPGRADE =================
// for contract upgrade, use below code.

// const ZentuStaking = await ethers.getContractFactory("ZentuStaking");
// await upgrades.upgradeProxy(
// "0xad2d1807b5B1a7473CA1f18Ad57F0948D4d0CbB6",
// ZentuStaking
// );
// console.log("Box upgraded");
}

//// for deployment
npx hardhat run scripts/deploy.js --network sepolia

//// for verification
npx hardhat verify {contract_address} --network sepolia

or

npx hardhat verify {contract_address} --network sepolia {constructor_args}

