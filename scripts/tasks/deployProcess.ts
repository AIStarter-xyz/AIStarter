import { task } from "hardhat/config"
import { readFileSync, writeFileSync } from "../helpers/pathHelper"
import { getAddress } from "ethers/lib/utils"


task("deploy:token", "Deploy Token")
  .addFlag("verify", "Validate contract after deploy")
  .setAction(async ({ verify }, hre) => {
    await hre.run("compile")
    const [signer]: any = await hre.ethers.getSigners()
    const feeData = await hre.ethers.provider.getFeeData()
    const MockToken = await hre.ethers.getContractFactory("contracts/mockToken.sol:MockToken")
    const MockTokenDeployContract: any = await MockToken.connect(signer).deploy({
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
      maxFeePerGas: feeData.maxFeePerGas,
      gasLimit: 6000000, // optional: for some weird infra network
    })
    console.log(`MockToken.sol deployed to ${MockTokenDeployContract.address}`)

    const address = {
      main: MockTokenDeployContract.address,
    }
    const addressData = JSON.stringify(address)
    writeFileSync(`scripts/address/${hre.network.name}/`, "MockToken.json", addressData)

    await MockTokenDeployContract.deployed()

    if (verify) {
      console.log("verifying contract...")
      await MockTokenDeployContract.deployTransaction.wait(3)
      try {
        await hre.run("verify:verify", {
          address: MockTokenDeployContract.address,
          constructorArguments: [],
          contract: "contracts/mockToken.sol:MockToken",
        })
      } catch (e) {
        console.log(e)
      }
    }
  },
  )

task("deploy:AIStarter", "Deploy AIStarter")
  .addFlag("verify", "Validate contract after deploy")
  .setAction(async ({ verify }, hre) => {
    await hre.run("compile")
    const [signer]: any = await hre.ethers.getSigners()
    const feeData = await hre.ethers.provider.getFeeData()
    const AIStarter = await hre.ethers.getContractFactory("contracts/AIStarter.sol:AIStarterPublicSale",)
    const token = readFileSync(`scripts/address/${hre.network.name}/`, "MockToken.json")
    const tokenAddress = JSON.parse(token).main
    const joinIdoPrice = "1000000000000000000"
    const rewardAmount = "1000000000000000000"
    const mFundAddress = "0x672e40055356401a364A253a88A465145CcCCEc9"
    const AIStarterDeployContract: any = await AIStarter.connect(signer).deploy(
      tokenAddress,
      joinIdoPrice,
      rewardAmount,
      mFundAddress,
      {
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        maxFeePerGas: feeData.maxFeePerGas,
        gasLimit: 6000000, // optional: for some weird infra network
      })
    console.log(`AIStarter.sol deployed to ${AIStarterDeployContract.address}`)

    const address = {
      main: AIStarterDeployContract.address,
    }
    const addressData = JSON.stringify(address)
    writeFileSync(`scripts/address/${hre.network.name}/`, "AIStarter.json", addressData)

    await AIStarterDeployContract.deployed()

    if (verify) {
      console.log("verifying contract...")
      await AIStarterDeployContract.deployTransaction.wait(3)
      try {
        await hre.run("verify:verify", {
          address: AIStarterDeployContract.address,
          constructorArguments: [
            tokenAddress,
            joinIdoPrice,
            rewardAmount,
            mFundAddress
          ],
          contract: "contracts/AIStarter.sol:AIStarterPublicSale",
        })
      } catch (e) {
        console.log(e)
      }
    }
  },
  )
