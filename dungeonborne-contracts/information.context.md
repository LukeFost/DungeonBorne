When working with Foundry through an LLM, always maintain context about the unique aspects of Forge testing and deployment. First, understand that Foundry tests are written in Solidity, not JavaScript like Hardhat, which means you're working with the same language as your contracts - this enables deeper testing capabilities but requires different patterns. Always consider that setUp() functions run before each test, not once for all tests, and state doesn't persist between tests. Be mindful that forge test verbosity levels (-v through -vvvvv) are crucial for debugging, with -vvv showing failed test traces and -vvvv showing all test traces. Remember that Foundry's cheatcodes (vm methods) are incredibly powerful - they're your main tools for testing state manipulation, like vm.prank(), vm.deal(), vm.expectEmit(), and vm.expectRevert(). When working with fork tests, always consider caching implications and use specific block numbers for deterministic behavior. The foundry.toml configuration is crucial - it controls everything from solc version to optimizer settings to test settings. For dependencies, remember Foundry uses git submodules by default, not npm, which means different dependency management patterns. Always consider remappings.txt for import paths - this is different from Hardhat's node_modules pattern. When dealing with events, remember Foundry's expectEmit pattern requires setting up the expected event before the actual call. For fuzz testing, consider that Foundry's approach is different from property-based testing in other frameworks - you can control runs with --fuzz-runs and seeds for reproducibility. When working with gas optimization, Foundry's gas reports are powerful but need to be explicitly enabled. Remember that Forge Standard Library (forge-std) provides many helpful utilities - prefer using Test.sol over raw DSTest. For contract-to-contract calls in tests, remember you're working with actual contract instances, not mocks like in JavaScript tests. Always consider that Foundry compilation caches aggressively - use forge clean when needed. When working with errors, prefer custom errors over require strings for gas efficiency and better testing. For logging, remember console.log works differently in Foundry - you need -vv to see logs. When dealing with time-based tests, remember vm.warp() and vm.roll() for time and block manipulation. For complex test scenarios, consider using abstract contracts for shared test functionality. When working with external services like Chainlink VRF, remember Foundry provides mock contracts but you need to handle their specific behaviors. Always consider that Foundry tests can interact with mainnet forks seamlessly - this is great for integration testing. Remember that Foundry's debugger (forge debug) is available for stepping through transactions. When dealing with large test suites, consider test organization patterns like grouping by feature or using shared fixtures. Always be aware that Foundry's gas reports can be misleading in tests due to test setup overhead. Consider using invariant testing for property-based checks across state changes. Remember that Foundry's coverage reports need to be explicitly enabled. When working with proxy patterns, remember Foundry can handle both creation and verification. Always consider that Foundry's test contracts are deployed at deterministic addresses. When dealing with large contracts, remember Foundry's IR pipeline can help with compilation of complex code. Consider using forge snapshot for gas optimization comparisons. Remember that Foundry's test matching can use wildcards and regex. When working with libraries, remember Foundry handles linking differently from Hardhat. Always consider that Foundry's traces show exact gas usage and call paths. When dealing with upgrades, remember Foundry can handle both transparent and UUPS patterns. Consider using forge script for deployment scripts instead of JavaScript. Remember that Foundry's test coverage tools work differently from solidity-coverage. When working with multiple contracts, consider using inheritance for test utilities. Always remember that Foundry's error messages are more precise than Hardhat's. Consider using foundry.toml profiles for different test configurations. Remember that Foundry's fuzzing is more powerful than most other frameworks' property-based testing. When dealing with storage slots, remember Foundry provides direct storage access. Always consider that Foundry's test isolation means each test starts with a fresh state. Remember that Foundry's cheatcodes can modify any blockchain state. Consider using forge format for consistent code formatting. When dealing with large test suites, remember Foundry's parallel test execution options.
 Protocol logo   RELOADED. Next level RPC is live. Try it for free!    Find out more Chainstack Product PricingEnterpriseCustomersBlog Developers Log in Start for free  Chainlink VRF Tutorial with Foundry – How To Use Chainlink’s VRF   Priyank Gupta October 12, 2022 in Tutorials Chainlink Foundry Solidity Web3 Banner for Tutorial on using Chainlink VRF with Foundry Table Of Contents-  • Introduction • Installing Foundry • Installing dependencies with forge • Setting up Remappings in Foundry • Creating a VRF Subscription • Writing the Smart Contract • Scripting in Foundry • Setting up our dotenv File • Deploying the Smart Contract • Fetching Random Values from VRF • Conclusion  Introduction  Foundry is one of the latest smart contract development toolchains currently in the market, and it allows users to compile contracts, write tests, deploy contracts, and much more through its command line interface.  Foundry is written in Rust and promises faster compilation times and the convenience of writing tests and deployment scripts in Solidity, rather than JavaScript. Many Solidity developers have been looking forward to this for a long time since this will allow people to write smart contracts and their corresponding tests without having to switch between languages. Moreover, this would save people time and effort by no longer needing to learn JavaScript and Solidity. If you’re familiar with Hardhat, we have an article covering the main differences between the two in performance and developer experience.   This article will teach you the basics of working with Foundry by building a smart contract that consumes Chainlink’s VRF (Verifiable Random Function). The smart contract will use a pre-paid ‘subscription’ to use Chainlink’s VRF services. We will compile, deploy, and verify our smart contract using Foundry, straight out of the command line. Without any further delays, let us get started.  How To Install Foundry?  To install Foundry, Linux and MacOS users can open their terminal and run-  curl -L https://foundry.paradigm.xyz | bash This will download Foundryup. To install Foundry, run-  foundryup If everything is installed correctly, your terminal will look like this-   Windows users may need to download Rust before proceeding with the installation. If you face any issues during installation, you can refer to the official Foundry documentation. Once this is done, create an empty directory where you would like to set up your Foundry project. Open the directory in VS code, and then open the terminal. Run the command ‘forge init’ to initialize a Foundry project in the empty directory.  Installing Dependencies with forge  By default, Foundry manages installed dependencies as submodules, which means any GitHub repository can be directly installed as a dependency without having to use a package manager like npm or yarn, even though Foundry supports that too.  So what exactly are we installing?  To fetch random data from Chainlink, our deployed smart contracts need to be structured in a way that is compatible with Chainlink’s on-chain smart contracts. To do that we will need to import a few interfaces and smart contracts into our Solidity code. To do that we will be installing a repository that contains only Chainlink’s smart contracts. You can check out the repository on Github. We will install the repo into our project using the forge command. In your terminal, run-  forge install smartcontractkit/chainlink-brownie-contracts The same command could be run by passing the exact URL of the repo instead of just the Github path. This will result in Foundry cloning the whole repo into our ‘lib’ folder.  Setting up Remappings in Foundry  While working with Foundry in VS Code, it is recommended that we precisely point Foundry towards the path of our installed dependencies. By default, Foundry makes some deductions. To check out those default remappings, run this command in your terminal-  forge remappings This should show you the exact paths of the packages that we are using with Foundry, alongside the path of the Chainlink repo we installed. However, we wish to set up a custom remapping for our Chainlink repo. In your terminal, run-  forge remappings > remappings.txt This will create a ‘remappings.txt’ file in your root directory and will fill it up with the default remappings that Foundry has. Add this line to your remappings file-  chainlink/=lib/chainlink-brownie-contracts/contracts/src/  All the files that we will need to inherit from Chainlink reside in the ‘src’ folder of our Chainlink library. Remapping our dependencies like this will make it easier to import those files into our Solidity code later. To verify that Foundry has saved your new remapping, run the ‘forge remappings’ command once more. Your terminal should look something like this-   How To Create a VRF Subscription?  Chainlink’s VRF V2 service charges a small amount of LINK tokens for every randomness request. Chainlink’s subscription manager lets us create a ‘subscription’ and fund it with a set amount of LINK tokens. Only contracts authorized by the owner of that subscription can use that subscription to request randomness. We can authorize multiple contracts on a single subscription, which not only makes this process more convenient but also saves us gas since we are funding a subscription with a significant amount of LINK tokens in one go.  To create a Chainlink VRF subscription on the Goerli testnet, follow these steps-  Go to faucets.chain.link and connect your wallet to the page. Now you can make a request for some LINK and ETH tokens. Make sure that your Metamask is connected to the Goerli Testnet. Go to vrf.chain.link and connect the wallet with some Goerli ETH and LINK tokens to the website. Click on ‘Create Subscription’. Make sure that the subscription address is the same wallet address that has the required tokens. Now click on ‘Create Subscription’ and approve the Metamask transaction. Once this transaction is confirmed, add a few LINK tokens to the subscription. This is known as ‘funding the subscription. Chainlink will then allow you to authorize contract addresses that can consume VRF data through your subscription, but we will add that address later. This is what your VRF homepage should look like-   Congrats! You now have your very own VRF subscription that you can use to fund the VRF requests that your smart contracts make.  Writing the Smart Contract  With our VRF subscription ready and our dev environment set up, we are now finally ready to write the smart contract code. Open the code editor where you set up your dev environment. Inside the src folder, create a new file:  chainlinkVRF.sol  Chainlink VRF example – Paste the following code inside the file  // SPDX-License-Identifier: MIT pragma solidity ^0.8.0; import "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; import "chainlink/v0.8/VRFConsumerBaseV2.sol";  contract VRFv2Consumer is VRFConsumerBaseV2 {   VRFCoordinatorV2Interface COORDINATOR;   // Your subscription ID.   //hardcoded into the constructor   uint64 s_subscriptionId;   // Goerli VRF v2 coordinator address   address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;   // The gas lane to use, which specifies the maximum gas price to bump to.   // Higher gas lane means higher price and lower confirmation times,   // mainnets on chainlink VRF typically have multiple gas lanes,   // but Goerli only has one gas lane. For more details,   // see https://docs.chain.link/docs/vrf-contracts/#configurations   bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;   //Goerli has a max gas limit of 2.5 million,    //we'll cap out at 200000, enough for about 10 words   uint32 callbackGasLimit = 200000;   // The default is 3, but you can set this higher.   uint16 requestConfirmations = 5;   // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.   //maximum number of random values is 500 for Goerli Testnet   uint32 public numWords =  3;   uint256[] public s_randomWords;   uint256 public s_requestId;   address s_owner;   constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {     COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);     s_owner = msg.sender;     s_subscriptionId = subscriptionId;   }   // Assumes the subscription is funded sufficiently.   function requestRandomWords() external onlyOwner {     // Will revert if subscription is not set and funded.     s_requestId = COORDINATOR.requestRandomWords(       keyHash,       s_subscriptionId,       requestConfirmations,       callbackGasLimit,       numWords     );   }   function fulfillRandomWords(     uint256, /* requestId */     uint256[] memory randomWords   ) internal override {     s_randomWords = randomWords;   }        //function to change the number of requested words per VRF request.   function changeNumOfWords(uint32 _numWords) public onlyOwner {     numWords = _numWords;   }    modifier onlyOwner() {     require(msg.sender == s_owner);     _;   } } A few things happened here. Let us quickly go over the important points to note in the code-  Notice the Chainlink imports at the top. We didn’t have to specify the exact path of the files we are importing, since we had already defined it in the ’remappings.txt’ file. This makes importing files into our code cleaner. The subscription ID is the unique identifier of our subscription and is passed as a parameter in the constructor. Each VRF-supported chain has a unique contract address representing the main VRF V2 smart contract. This address is passed to both the inherited interface as a reference later.  A key hash address is basically a measure of how much gas you are willing to pay to process your requests. The higher the ‘gas lane’, the quicker will your requests go through. Do note however that not every chain has high-speed gas lanes. Chainlink supports only one gas lane, whereas the Ethereum mainnet supports multiple gas lanes. You can read more about the exact specifications for each network from Chainlink’s official documentation.   To supply random values to your smart contract, Chainlink basically uses a fallback function. We need to supply an adequate amount of gas so that our call does not fail. The exact amount of gas required can vary wildly depending on the instantaneous chain activity, but you can check out some rough estimates in the code’s comments.   As a rule, you will be charged for the work already done if your callback function fails due to a lack of gas. The ‘requestConfirmations’ variable represents the number of block confirmations we want to wait for before accepting the returned random values from Chainlink. The higher this number, the more secure your data is. However, there are constraints placed upon the value of this variable, and you can read about the exact details in the docs.   ‘requestRandomWords()’ sends a request to Chainlink’s V2 coordinator for a supply of random words. Every single one of these requests has a unique ID. The ‘fulfillRandomWords()’ function uses this unique ID to fetch our Random data.   The last function simply manipulates the ‘numWords’ variable so that we can change the number of random values we can ask for in a single call.  Once your contract is ready, save the files and run this command in the terminal-  forge build This will compile all your contracts and generate ABIs for them.  Scripting in Foundry  Once our contracts have been successfully compiled, we need to create a simple script to deploy our contract. Under the ‘script’ folder, create a new file by the name of ‘chainlinkVRF.s.sol’. Inside the file, paste the following code-  // SPDX-License-Identifier: UNLICENSED pragma solidity ^0.8.0; import "forge-std/Script.sol"; import {VRFv2Consumer} from "src/chainlinkVRF.sol"; contract ChainlinkScript is Script {     function setUp() public {}     function run() public {         vm.startBroadcast();         VRFv2Consumer VRFv2 = new VRFv2Consumer(1810);         vm.stopBroadcast();     } } We don’t do a whole lot here. We first import the Script.sol contract from Foundry, which allows us access to all the scripting functionalities supported by Foundry. Secondly, we import our smart contract. Scripts are by default executed within the function run(). The two broadcast functions record any transactions happening between the two calls and record them to a special file.  One thing to note here is the constructor we are passing to our smart contract. If you look carefully at the code, the ID of our Chainlink subscription is passed as a parameter. Copy the subscription ID from the subscriptions page and pass it as the parameter to your contract. Lastly, we create a new instance of our contract, which serves as the deployment command. We now have a script ready to run, but we still need to define our environment variables to correctly deploy our smart contract.  Setting up our dotenv File  This is the last thing we need to do before getting started with our smart contract. To deploy our smart contract, we will need to pass a few environment variables to Foundry. We could do this directly in the command line while deploying our contract, but it is recommended that we do so in a dotenv file. This way our sensitive data remains secure. In your terminal, make sure you are pointing to the root directory, and run the following command-  touch .env This will create an empty dotenv file in your directory. Now we need to get some credentials to put into our dotenv file. Here’s how to do that-  RPC URLs are needed to connect to the blockchain. You can either host your own node or connect to the blockchain using the RPC URL for the blockchain network you want to use. In this example, we are going to use Ethereum’s Goerli Testnet. You can either use a public Goerli RPC URL or Chainstack’s dedicated node provider service. That’s what I am doing here. Using Chainstack allows us to deploy our contracts and interact with them much more quickly and reliably. Get started from our signup page. A private key is what enables Foundry to access the tokens needed to be used as gas fees to deploy our contract. Pass in the private key for any of your accounts with some Goerli testnet tokens. Lastly, you need to go to Etherscan and sign up for an account if you haven’t already done so. Then create an Etherscan API key and paste it here. You will need this to verify the contract. In the end, your dotenv file should look something like this-  RPC_URL=https://mc-12.p123yippy.com/12ase525c5012 PRIVATE_KEY=dlhj12342kjh4eslkh1pq4h1324kqwrekhwe ETHERSCAN_API_KEY=SDJKASL232KJ3SQINA11A5KQIUALKJ234G2CAEWYND Do note however that the keys shown here are fake and are displayed this way for your convenience. After configuring the dotenv file, save it once. Then open the terminal again, and run the command-  source .env This command allows us to load our environment variables from the dotenv file to the terminal. Now we are finally ready to deploy our contract.  Deploying the Smart Contract  In your terminal, execute the following command-  forge script script/chainlinkVRF.s.sol:ChainlinkScript --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv This command tells forge to run our script on the Goerli Testnet, and to verify our contract immediately after running the script. Please note that it may take a while to complete this transaction if the network is busy. You can mitigate some of that time if you are using a dedicated node. Also, the ‘-vvvv’ flag represents the amount of verbosity, i.e- the amount of details, you want in your transaction logs. Foundry allows us different levels of verbosity. Once your transaction is through, your terminal should look something like this-   Open the goerli.etherscan URL and open the contracts page. You will see that your contract has already been verified, and that you can call your functions directly from the contract page. Your browser should look something like this-   Fetching Random Values from VRF  Congratulations on deploying a VRF-compatible smart contract. This smart contract is now capable of requesting provably random values from Chainlink. However, we still need to allow our smart contract access to the subscription we made earlier. Open your browser and go back to vrf.chain.link . Click on the subscription ID you passed to the contract as the constructor argument at the time of deployment. Copy the address of the deployed smart contract and add it as an authorized consumer of this subscription. This is what your screen should look like.   Once this transaction is done, go to the write section of your verified contract page. Connect your Metamask wallet to Etherscan. Again, make sure it is the same wallet you deployed the contract with. Call the function ‘requestRandomWords’ and approve the transaction. This process takes a while. Chainlink not only generates a random number for us, but it also verifies its authenticity on-chain, and that takes a while to process. After a few minutes, go to the read section of your contract, and call the ‘s_randomWords’ variable by passing 0 as the array index. Note that Chainlink will return an array of random uint256 numbers whose length will be equal to the value of the ‘numWords’ variable. This is what your screen should look like.   You can now use these random numbers in any of your projects without having to worry about the reliability of these values.  Conclusion  And that’s it. Congratulations if you made it this far. In this tutorial, we used Foundry to compile and deploy a smart contract to the Goerli Testnet. The contract I deployed can be found on etherscan. Feel free to check out Chainstack’s official blog for some other cool tutorials. Happy coding!  Discover how you can save thousands in infra costs every month with our unbeatable pricing on the most complete Web3 development platform. Input your workload and see how affordable Chainstack is compared to other RPC providers. Connect to Ethereum, Solana, BNB Smart Chain, Polygon, Arbitrum, Base, Optimism, Avalanche, TON, Ronin, zkSync Era, Starknet, Scroll, Aptos, Fantom, Cronos, Gnosis Chain, Klaytn, Moonbeam, Celo, Aurora, Oasis Sapphire, Polygon zkEVM, Bitcoin, Tezos and Harmony mainnet or testnets through an interface designed to help you get the job done. To learn more about Chainstack, visit our Developer Portal or join our Discord server and Telegram group.  Are you in need of testnet tokens? Request some from our faucets. Multi-chain faucet, Sepolia faucet, Holesky faucet, BNB faucet, zkSync faucet, Scroll faucet. Have you already explored what you can achieve with Chainstack? Get started for free today.  SHARE THIS ARTICLE    Table Of Contents-  Introduction  How To Install Foundry?  Installing Dependencies with forge  Setting up Remappings in Foundry  How To Create a VRF Subscription?  Writing the Smart Contract  Chainlink VRF example – Paste the following code inside the file  Scripting in Foundry  Setting up our dotenv File  Deploying the Smart Contract  Fetching Random Values from VRF  Conclusion   Querying full and archive Ethereum nodes with Python  Whenever we need to query data from the blockchain, we fetch it from a node. An archive node differs from a full node since the first holds the entire history of network transactions. Thus, some queries for older block transactions cannot be fetched easily on a full node. In this tutorial, we will programmatically fetch data from the blockchain, switching between full and archive nodes when necessary.   Bastian Simpertigue Sep 22  Unstoppable Web3 development with Chainstack Elastic Nodes  See how we empower Web3 developers with our award-winning Elastic architecture for unparalleled performance, customization, and 99.9% uptime.   Petar Stoykov Dec 13 Customer Stories   FailSafe FailSafe revolutionizes Web3 security to reduce latency, boost transaction volumes, and user safety with Chainstack RPCs.   DeFiato Securing a stable environment for platform operations with ease.   TrustPad Creating a better crowdfunding environment by reducing the number of dropped requests. footer subedevice footer subefooter dotsfooter ringfooter shape See Chainstack in action Managed blockchain services making it simple to launch and scale decentralized networks and applications.  Start for free newsletter Never miss an update Our monthly newsletter is the perfect way to stay up-to-date with the latest industry news, product updates, and exclusive promotions.   By ticking this box you give Chainstack your consent to store and process your email address to send you updates. You can unsubscribe from our communications at any time, more details on our T&C and Privacy Policy. I agree to receive communications from Chainstack*   United States 1 Van de Graaff Drive Burlington, MA 01803  Singapore 8 Temasek Boulevard #30-01/02, Suntec Tower 3 038988              Chainstack © 2024 Platform  Solution Pricing Customers Marketplace Hosting Chainstack Cloud IPFS Dedicated subgraphs Chains  Ethereum Solana BNB Smart Chain Polygon Arbitrum Base Optimism Avalanche TON Ronin Blast zkSync Era Starknet Scroll Aptos Fantom Cronos Gnosis Chain Kaia Moonbeam Celo Aurora Oasis Sapphire Polygon zkEVM Bitcoin Tezos Harmony Resources  Blog Newsletter Newsroom Press kit Whitepapers Company  About us Contact us Careers Ambassadors Labs Security SLA Support  Help center Developer portal Terms of service Privacy policy Status Cookie settings

 ChainlinkVRF.t.sol

💻 The code corresponding to this page can be found on Github at ChainlinkVRF.t.sol 💻

Create a file named ChainlinkVRF.t.sol inside your Foundry project.

To test our VRF contract using the VRFCoordinatorV2Mock, set up the test file with the following imports:

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {ChainlinkVRF} from "./ChainlinkVRF.sol";
Next, initialize a contract named ChainlinkVRF_test:

contract ChainlinkVRF_test is Test {

}
We need to declare a few state variables:

    // Initializing the contract instances
    ChainlinkVRF public chainlinkVRF;
    VRFCoordinatorV2Mock public vrfCoordinatorV2Mock;

    // These variables will keep a count of the number of times each
    // random number number was generated
    uint counter1; uint counter2; uint counter3;
The counter1, counter2andcounter3variables will keep a count of the number of times each of the respective random numbers was generated. Now let us define thesetUp()` function to set up the initial state:

    function setUp() public {
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        uint64 subId = vrfCoordinatorV2Mock.createSubscription();

        //funding the subscription with 1000 LINK
        vrfCoordinatorV2Mock.fundSubscription(subId, 1000000000000000000000);

        chainlinkVRF = new ChainlinkVRF(subId, address(vrfCoordinatorV2Mock));
        vrfCoordinatorV2Mock.addConsumer(subId, address(chainlinkVRF));
    }
We do a few things here:

We initialize a new VRFCoordinatorV2Mock contract with some dummy values.
Then we programmatically create a new subscription and fund it with 1000 LINK tokens.
Next, we initialize a new instance of the ChainlinkVRF contract.
Finally, we add the ChainlinkVRF contract as an approved consumer of the subscription we created earlier.
Let us now create a testrequestRandomWords() function to check if our contract is consuming the VRF service correctly. This will however be a slightly different test than the ones we have written before.

This function will not have an assertion that it may or may not pass. Test functions written without any assertions always pass. We will however use the console2 contract from Forge's test suite to log out the random numbers generated by our contract.

We can check how many times each number was generated by looking at the counter1, counter2 and counter3 variables. This will help us see if the probability of the numbers being generated is along the desried lines.

function testrequestRandomWords() public {

        for(uint i = 0; i < 1000; i++)
        {                    
            uint256 requestId = chainlinkVRF.requestRandomWords();
            vrfCoordinatorV2Mock.fulfillRandomWords(requestId, address(chainlinkVRF));

            if(chainlinkVRF.number() == 1){
                counter1++;
            } else if(chainlinkVRF.number() == 2){
                counter2++;
            } else {
                counter3++;
            }   
        }

        console2.log("Number of times 1 was generated: ", counter1);
        console2.log("Number of times 2 was generated: ", counter2);
        console2.log("Number of times 3 was generated: ", counter3);
    }
I can run the test file with this command:

forge test --match-path src/Applications/Chainlink/ChainlinkVRF/ChainlinkVRF.t.sol -vv
Although the exact command may vary on how you have set up your project. Again, this test will always pass since it does not have any assertions.

However we can derive conclusions by looking at the logged values. This is what the output of the test looks like on my terminal:
ChainlinkVRF.sol

💻 The code corresponding to this page can be found on Github at ChainlinkVRF.sol 💻

Creating a VRF subscription

Unlike the price feeds service, Chainlink VRF is not free to use. Each randomness request costs a certain amount of LINK tokens.

There are two ways to pay for a VRF request:

Direct Funding: Your smart contract directly pays a small amount of LINK tokens with each request.
Subscription Method: You fund a single subscription with LINK tokens, and add your smart contracts as approved consumers of that subscription. Each time your smart contract makes a randomness request, the subscription is charged a small amount of LINK tokens.
We will be using the subscription method in this tutorial.

These are the steps to set up a VRF subscription:

Make sure you have some LINK tokens in an EOA. You can get a few from Chainlink's faucet.
Go to vrf.chain.link and create a new subscription. I will be working with the Sepolia testnet.
Fund your subscription with some LINK tokens(50 should be more than enough).
We are now ready to start writing our smart contract.

Writing the smart contract

To get started, create a new file called ChainlinkVRF.sol inside your Foundry project.

We need to import two things into our contract:

VRFCoordinatorV2Interface: Each network supported by Chainlink has an on-chain coordinator contract that handles all VRF requests. use this interface to interact with the coordinator contract.
VRFConsumerBaseV2: This is an abstract contract, which means this is an incomplete contract with at least one of its functions left unimplemented. We will inherit from this contract and implement the missing function, fulfillRandomWords().
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/v0.8/VRFConsumerBaseV2.sol";
Next, let us initialize a contract named ChainlinkVRF:

contract ChainlinkVRF is VRFConsumerBaseV2 {

}
To send a randomness request to Chainlink VRF, we need to configure a few variables. Let us take a look:

keyHash: Each keyHash is a hexadecimal value that represents a 'gas lane'. Each gas lane costs a different amount of gas.
subId: The subscription ID of the subscription we created earlier.
minimumRequestConfirmations: The number of blocks you would like the off-chain node to wait before fulfilling your request. The higher this number, the more secure your randomness will be.
callbackGasLimit: How much gas would you like to be used on your callback function.
numWords: The number of uint256 values you would like to receive. We will be requesting 1 word.
📝 Note: All of these values will differ depending on the network you are working with. You can find the technical reference for all supported networks here.

Let us configure these variables:

    VRFCoordinatorV2Interface private CoordinatorInterface;
    uint64 private _subscriptionId;
    bytes32 private constant KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant BLOCK_CONFIRMATIONS = 10;
    uint32 private constant NUM_WORDS = 1;

    // Variable to store the generated random number
    uint256 public number;
The CoordinatorInterface and _subscriptionId variables will be initialized in the constructor. The number variable will store the generated random number.

The constructor can be initialized as follows:

    constructor(uint64 subscriptionId, address vrfCoordinatorV2Address) VRFConsumerBaseV2(vrfCoordinatorV2Address) {
        _subscriptionId = subscriptionId;
        CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
    }

Let us now define a function named useChainlinkVRF() that will send a randomness request to the Chainlink VRF coordinator contract. This function will send a randomness request to the coordinator contract, and return a requestId that will be used to identify the request.

     function useChainlinkVRF() public returns (uint256 requestId) {
        requestId = CoordinatorInterface.requestRandomWords(
            KEY_HASH,
            _subscriptionId,
            BLOCK_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        return requestId;
    }
Lastly, we need to define the fulfillRandomWords() function. This function will be called by the Chainlink VRF coordinator contract once the randomness request has been fulfilled by the off-chain Chainlink node.

We can modulo the huge random number we get back to trim it down to a desired range. Based on the number we get back, we will set the number variable to 1, 2, or 3.

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

        // To get a random number b/w 1 and 100 inclusive
        uint256 randomNumber = (randomWords[0] % 100) + 1;

        if(randomNumber == 100){
            number = 1;
        } else if(randomNumber % 3 == 0) {
            number = 2;
        } else {
            number = 3;
        }
    }
And that's it for now. By calling the useChainlinkVRF() function on our contract, a user can get back a random number b/w 1 and 3 with a varying degree of probability.

In the next section, we will use the VRFCoordinatorV2Mock to write a preliminary test for our VRF contract.
Boolean

A bool variable can have two values: true or false. Solidity supports the following operations on booleans:

== (equality)
!= (inequality)
! (logical negation)
|| (logical disjunction, “OR”)
&& (logical conjunction, “AND”)
Integers

Solidity supports signed and unsigned integers of various sizes. They are represented using the int and uint keywords respectively, followed by the number of bits they occupy. For example, int256 is a signed integer occupying 256 bits, and uint8 is an unsigned integer occupying 8 bits.

Solidity supports integers of sizes 8 bits to 256 bits, in steps of 8. Integers can be initialized as int or uint without specifying the number of bits they occupy. In this case, they occupy 256 bits.

📝 Note: All integers in Solidity are limitied to a certain range. For example, uint256 can store a value between 0 and 2256-1. Since int256 is a signed integer, it can store a value between -2255 and 2255-1.

Addresses

An address variable stores a 20-byte/160-bits value (size of an Ethereum address).

📝 Note: EVM addresses are 40 characters long, however they are often represented as hexadecimal strings with a 0x prefix. But strictly speaking, the address itself is 40 characters.

Solidity allows us to initialize a variable of type address in two ways:

address: A simple 20-byte value that represents an EVM address. We can query the balance of an address variable using the balance() method.
address payable: Any address variable initialzed with the payable keyword comes with two additional functions, transfer() and send(), that allow us to send ETH to the address.
Any integer can be typecasted into an address like this:

address(1) == address(0x1) == 0x0000000000000000000000000000000000000001
In this case, the integer 1 will be treated as a uint160, which can be implicitly converted into an address type.

Enums

Enums are a user-defined type that can have upto 256 members. They are declared using the enum keyword. Each member of an enum corresponds to an integer value, starting from 0. However, each member can be referenced directly by using its' explicit name.

Consider this example:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TestEnum {
    // Define an enum named Directions
    enum Directions { Center, Up, Down, Left, Right }

    // Declare a state variable of type Directions with default value (Center, the first enum member)
    Directions public defaultDirection;

    // Declare and initialize another state variable
    Directions public setDirection = Directions.Right;

    // Change the direction
    function changeDirection(Directions newDirection) public {
        setDirection = newDirection;
    }

    // Get the maximum value of the Directions enum (i.e., Right in this case)
    function getMaxEnumValue() public pure returns (Directions) {
        return type(Directions).max;
    }
}
Fixed-size byte arrays

The bytes type is used to store raw byte data. Even though bytes are always stored as an array of characters, fixed-size byte arrays are a value type, while dynamic-size byte arrays are reference type.

A fixed size byte array can be anywhere between 1 and 32 bytes in size. They are declared as: bytes1, bytes2, bytes3, .............. bytes32.

Each byte can store 2 characters. Therefore, a bytes20 variable can store upto 40 characters, enough for an Ethereum address.

📝 Note: All byte variables come with a length property that can be used to get the length of the bytes array.

Here is a code snippet that demonstrates the use of fixed-size byte arrays:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ByteContract {

    // Declare a bytes20 variable to store data
    bytes20 public data;

    // Function to set data
    function setData(bytes20 _data) public {
        data = _data;
    }

    // Function to get the length of the bytes variable
    function getFirstByte() public view returns (bytes1) {
        return data[0];
    }

    function getLength() public view returns (uint){
        return data.length;
    }
 
}

Visibility.sol

💻 The code corresponding to this page can be found on Github at Visibility.sol.

Let us define a few state variables and functions of different visibility types. We will then call a few of them from a contract that inherits from our main contract.

Define the main contract like this:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Parent {

    // State variables cannot be marked external
    string public publicString = "Public String";
    string private privateString = "Private String";
    string internal internalString = "Internal String";

    /**
     * @dev Declaring 4 consecutive functions with different visibilities that do the same thing
     * @param (a , b) each function takes two variables as params and returns the sum.
     */
        
    function publicAddition(uint a , uint b) public pure returns (uint) {
        return a+b;
    }

    function privateAddition(uint a , uint b) private pure returns (uint) {
        return a+b;
    }

    function internalAddition(uint a , uint b) internal pure returns (uint) {
        return a+b;
    }

    function externalAddition(uint a , uint b) external pure returns (uint) {
        return a+b;
    }


    /**
     * @dev We cannot call external functions from within the same contract.
            Note that since all the functions that are calling the functions
            above are marked public, the visibility specifiers don't do much 
            in our code. Not meant for production.            
    */

    function callPrivateAddition(uint a , uint b) public pure returns (uint) {
        return privateAddition(a , b);
    }

    function callPublicAddition(uint a , uint b) public pure returns (uint) {
        return publicAddition(a , b);
    }

    function callInternalAddition(uint a , uint b) public pure returns (uint) {
        return internalAddition(a , b);
    }
ov
}
Now let us define a child contract that inherits from the main contract, and calls a few of the functions and variables defined in the main contract.

contract Child is Parent {

    /**
     * @dev We cannot call private or external functions from inside a child contract.          
    */

    function  callInternalAdditionInParentFromChild(uint a , uint b) public pure returns (uint) {
        return internalAddition(a , b);
    }

    function callPublicAdditionInParentFromChild(uint a , uint b) public pure returns (uint) {
        return publicAddition(a , b);
    }

    function callInternalStringInParentFromChild() public view returns (string memory) {
        return internalString;
    }

}
📝 Note: Note that I haven't shown you how to call external functions of a contract from another contract. To understand how to do that, you will need to understand how interfaces work in Solidity. We will learn how to call external functions in the interfaces section.
Visibility.t.sol

💻 The code corresponding to this page can be found on Github at Visibility.t.sol

As usual, create a new file and import the required Solidity files to initialize the test contract:

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import "./Visibility.sol";

contract Visibility_test is Test {

}
Now, define the setup() function that sets the initial state for each test function:

    Child child;

    function setUp() public {
        child = new Child();
    }
Next, make sure we can call the internal and public addition functions defined in the parent contract, from within the child contract:

    function test_callInternalAdditionInParentFromChild() public {

        uint a = 10; uint b = 20;
        uint c = child.callInternalAdditionInParentFromChild(a , b);

        // test passes if the value of (a + b) is returned correctly 
        assertEq(c, 30);
    }

    function test_callPublicAdditionInParentFromChild() public {

        uint a = 10; uint b = 20;
        uint c = child.callPublicAdditionInParentFromChild(a , b);

        // test passes if the value of (a + b) is returned correctly 
        assertEq(c, 30);
    }
Finally, let us see if we can call the internal string defined in the parent contract, from within the child contract:

    function test_callInternalStringInParentFromChild() public {

        string memory str = child.callInternalStringInParentFromChild();

        // test passes if the value of internalString is returned correctly 
        assertEq(str, "Internal String");
    }
To run the test file I need to run this command in my terminal:

forge test --match-path src/SolidityBasics/Visibility/Visibility.t.sol
Please note that the exact command will vary depending on your directory structure.

Library

Initialized using the library keyword, libraries in Solidity are usually a collection of view and pure functions that are expected to be used by multiple contracts. A library is not 'inherited' as you would inherit a contract. A library is natively accessible to all contracts in the same file, and can be imported into other files as well. Using a library in these cases abstracts away commonly used code and helps in building a more modular codebase. Libraries are mainly distinguished by the visibility of the functions defined within them. A library can have internal, external or public, functions but not private functions.

A library with only internal functions is deployed alongside the contract that uses it, and the code of the library is included in the bytecode of the contract. On the other hand if your library has external or public functions, it is deployed separately and your contract has to be linked to that deployment manually to perform DELEGATECALL(s) to it.

Example

This is how you would define a library in Solidity:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Define a library named MathLib
library MathLib {

    function cubeRoot() internal pure returns (uint256) {
        // ...
    }
}

// Define a contract that uses the library
// Note that the library is not inherited

contract Calculator {

    function calculateCubeRoot(uint256 _num) public pure returns (uint256) {
        // Call the cubeRoot function defined in the library
        return MathLib.cubeRoot(_num);
    }
}
In this tutorial, we will:

Take a look at what CREATE3 is and how it works.
We will look at an implementation of the concept using the famous solady repo.
Test and deploy a CREATE3 factory contract on multiple chains to the same address.
Use these factories to deploy two different contracts on two chains to the same address.
Chainlink Data Feeds

Chainlink's data feeds are a collection of data points from Chainlink's decentralized oracle network.

Chainlink offers a wide variety of data feeds, but in this tutorial we will be going over their price feeds service. Each Chainlink price feed returns the relative price of two assets, such as ETH/USD or BTC/USD.

We will write a simple smart contract that consumes Chainlink's data feeds, and then a Foundry test for that smart contract.

Briefly, here is how Chainlink's price feeds service works:

Chainlink has a network of off-chain nodes that fetch the latest prices of different assets and arrive at a consensus in real-time. These prices are fed into an on-chain aggregator contract.

Each price feed has its' own aggregator contract.

To query the latest relative price of any two assets, we simply need to call the latestRoundData() from the designated contract of that price feed.

ChainlinkDataFeeds.sol

💻 The code corresponding to this page can be found on Github at DataFeeds.sol 💻

Before getting started with the actual code, we need to install the dependencies for this project. Make sure you have a Foundry project initialized before moving on.

Installing dependencies

Dependencies in a Foundry project are managed using git submodules by default. For this project, we will be using a slimmed down version of Chainlink's official smart contracts repo.

To download the repo into the lib directory, run:

forge install https://github.com/smartcontractkit/chainlink-brownie-contracts/
or simply

forge install chainlink-brownie-contracts
📝 Note: In my experience, Forge may sometimes install outdated versions of the dependencies. Run forge update after installing new dependencies to make sure you have the latest versions.

Remapping dependencies

While working with installed dependencies, we may need to explicitly tell Forge where to look for the code. This can be done by defining your remappings inside a separate file. To create this file, run:

forge remappings > remappings.txt
This will create a remappings.txt file in the root directory of your project. For now, delete everything inside the default remappings file and add the following two remappings inside:

forge-std/=lib/forge-std/src/
@chainlink/=lib/chainlink-brownie-contracts/contracts/src/
The forge-std remapping is used to tell Forge where to look for the Forge standard library. The @chainlink remapping abstracts away the path to the Chainlink contracts.

Writing the smart contract

To get started, create a new file called DataFeeds.sol inside your Foundry project.

As mentioned earlier, to use Chainlink's price feeds service, you simply need to query the designated aggregator contract for the specific price feed you want to use. Since all of Chainlink's pricde feeds contracts are built on top of a single interface, we can use the same interface to interact with all of them.

To get started, import the AggregatorV3Interface into your contract code:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
Next, initialize a contract named ChainlinkDataFeeds :

contract ChainlinkDataFeeds {
    
}
Inside the contract:

Declare a variable of the type AggregatorV3Interface.
Inside the constructor, initialize the new variable by passing the address of the aggregator contract you want to use.
    AggregatorV3Interface internal immutable priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
Finally, define a function named getLatestPrice() that performs an external call to the latestRoundData() function of the aggregator contract:

    function getLatestPrice() public view returns (uint80 roundID, int price) {
        (roundID, price ,,,) = priceFeed.latestRoundData();
        return (roundID, price);
    }
While we are only dealing with two values, the latestRoundData() function actually returns:

roundId: Chainlink's data feeds are updated with each 'round'. This value is the ID of the current round.
answer: The actual data returned by the data feed. While we are working with price feeds, this value could be anything, depending on the actual data feed you are working with.
startedAt: Unix timestamp of when the round started.
updatedAt: Unix timestamp of when the round was updated.
answeredInRound: Deprecated
And that is it for the contract. Before deploying it though, we need to be familiar with a few concepts related to Chainlink's price feeds:

The complete reference for each price feed offered by Chainlink across all of its' networks can be found in their docs.
Different price feeds may vary in their level of precision. For example, on ETH mainnet, the price feed for ETH/USD returns the price in 8 decimals, while the price feed for BTC/ETH returns the price in 18 decimals. The result needs to be dividied by 10 to the power of the number of decimals to get the actual price.
Each price feed has a set 'heartbeat'. This is the default time interval between each update of the price feed.
Each price also has a deviation threshold. If the price deviates from the previous price by more than this percentage, it is updated immediately.
ChainlinkDataFeeds.t.sol

💻 The code corresponding to this page can be found on Github at DataFeeds.t.sol 💻

Create a file named ChainlinkDataFeeds.t.sol. To check if our contract is correctly configured to read from Chainlink's aggregator contracts, we will take the help of the MockV3Aggregator contract.

This contract will mock the behavior of the aggregator contracts, and will allow us to test our contract without having to deploy it to a testnet. If our contract can read from this mock aggregator contract, it will likely be able to read from the real aggregator contracts as well, since they are built on top of the same interface.

To get started, create a file named DataFeeds.t.sol. Inside the file, make the following imports:

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ChainlinkDataFeeds} from "./ChainlinkDataFeeds.sol";
import {MockV3Aggregator} from "@chainlink/v0.8/tests/MockV3Aggregator.sol";
Next, initialize a contract named ChainlinkDataFeeds_test:

contract ChainlinkDataFeeds_test is Test {

}
The MockV3Aggregator contract needs to be initialized with some dummy data. Declare the following state variables inside the ChainlinkDataFeeds_test contract:

    // Configuring the base data for the mock aggregator
    uint8 public _decimals = 8;
    int256 public _initialAnswer = 10**18;

    // Initializing the contract instances
    ChainlinkDataFeeds public chainlinkDataFeeds;
    MockV3Aggregator public mockV3aggregator;
The setUp() function is a special function that if often used while writing tests in Foundry. This function is executed by Forge before every single test function in a file. This allows us to set up an initial state that we can use to test our contracts on.

    function setUp() public {

        mockV3aggregator = new MockV3Aggregator(_decimals, _initialAnswer);
        chainlinkDataFeeds = new ChainlinkDataFeeds(address(mockV3aggregator));
    }
Finally, we define a function named testgetLatestPrice(). This function will call the getLatestPrice() function on our contract, which in turn calls the latestRoundData() function on the mock aggregator contract. We then check if the values returned by the getLatestPrice() function are the same as the values we initialized the mock aggregator contract with.

If the values are in-line with what we expect, we can be certain that our contract is correctly configured to read from Chainlink's aggregator contracts.

    function testgetLatestPrice() public {

        (uint80 roundID, int256 price) = chainlinkDataFeeds.getLatestPrice();
        
        assertEq(price, _initialAnswer);
        assertEq(roundID, 1);
    }

    ChainlinkDataFeeds.s.sol

💻 The code corresponding to this page can be found on Github at ChainlinkDataFeeds.s.sol

The best way to deploy contracts using Foundry is to use the write a simple deploy script. However, we first need to set up a dotenv file to store our environment variables.

At the root of your project, create a file named .env. Fill out your environment variables like this:

# Alchemy RPC URLs
SEPOLIA_RPC_URL=

# Private Key
PRIVATE_KEY=

# Etherscan and Polygonscan API keys
ETHERSCAN_API_KEY=
You can get RPC URLs from Alchemy, or any other RPC provider. You can also use a public RPC URL.
Make sure to use the private key of a wallet that has some Sepolia ETH. You can get some from Alchemy's Sepolia faucet.
Get your Etherscan API key from Etherscan's website.
Once your environment variables are set up, run source .env to load them into your shell. Let us now write a script to deploy the data feeds contract.

📝 Note: This is really, really important. Whatever happens, make sure to NOT push your env variables to Github. To make sure that doesn't happen, add .env to your .gitignore file. Please note that even using a normal dotenv file is not recommended behaviour. Ideally you should be using a hardware wallet, and/or an encrypted keystore. But for the sake of simplicity, I'll be using a dotenv file throughout.

Create a file named ChainlinkDataFeeds.s.sol, and initialize a deployment contract like this:

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {ChainlinkDataFeeds} from "./ChainlinkDataFeeds.sol";

contract DeployDataFeed is Script {

}
This contract is executed using the forge script command. Next, within the DeployDataFeeds contract, initialize an instance of the data feeds contract, and define a function named run():

 ChainlinkDataFeeds chainlinkDataFeeds;

    function run() external {
        
        // Using the envUint cheatcode we can read some env variables
        uint256 PrivateKey = vm.envUint("PRIVATE_KEY");

        // Anything within the broadcast cheatcodes is executed on-chain
        vm.startBroadcast(PrivateKey);
        chainlinkDataFeeds = new ChainlinkDataFeeds(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.stopBroadcast();
    }
A few things happen here:

The run() function serves as the default entry point for the script.
We can use the envUint() cheatcode to read environment variables from the .env file. This way we don't have to pass the private key as a command line argument.
The startBroadcast() and stopBroadcast() cheatcodes are used to execute the code on-chain. Anything within these two cheatcodes is executed on-chain.
Finally, the new instance of the data feeds contract is passed an address as an argument. This address is the address of the aggregator contract that serves the ETH/USD price feed on the Sepolia testnet.
Save everything and run forge build to make sure everything compiles correctly. To run the script, use the forge script command like this:

forge script src/Applications/Chainlink/ChainlinkDataFeeds/ChainlinkDataFeeds.s.sol:DeployDataFeed \
--rpc-url $SEPOLIA_RPC_URL \
--broadcast -vvvv
The exact params may of course differ depending on your setup. To verify the contract once it is deployed, run:

forge verify-contract <Your contract address> \
--chain-id 11155111 \
--num-of-optimizations 200 \
--watch --compiler-version v0.8.19+commit.7dd6d404 \
--constructor-args $(cast abi-encode "constructor(address)" 0x694AA1769357215DE4FAC081bf1f309aDC325306) \
src/Applications/Chainlink/ChainlinkDataFeeds/ChainlinkDataFeeds.sol:ChainlinkDataFeeds \
--etherscan-api-key $ETHERSCAN_API_KEY
📝 Note: It is possible to verify the contract your contract at the time of deployment by passing the --verify flag to the forge script command. However, this way of verification fails more often than not in my experience. You can read more about this in Foundry's do

UsingInterface.sol

💻 The code corresponding to this page can be found on Github at UsingInterface.sol

Let us write the UsingInterface.sol, that will use the Interface_SimpleAddition to call functions on the SimpleAddition contract.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/* Note that we only import the interface, not the actual contract
   we will be calling.
*/
import {Interface_SimpleAddition} from "./Interface_SimpleAddition.sol";

contract UsingInterface {

    Interface_SimpleAddition public IsimpleAddition;

    constructor(address _simpleAdditionAddress) {
        IsimpleAddition = Interface_SimpleAddition(_simpleAdditionAddress);
    }

    function setA(uint256 _a) public {
        IsimpleAddition.setA(_a);
    }

    function setB(uint256 _b) public {
        IsimpleAddition.setB(_b);
    }

    function returnSumOfStateVariables() public view returns (uint256) {
        return IsimpleAddition.returnSumOfStateVariables();
    }

    function returnSumOfLocalVariables(uint256 _a, uint256 _b) public view returns (uint256) {
        return IsimpleAddition.returnSumOfLocalVariables(_a, _b);
    }

}
A few notes:

The UsingInterface contract takes the address of the SimpleAddition contract as a constructor param. This is needed because the actual functions will be called on an already deployed contract.
An instance of the Interface_SimpleAddition interface can then be used to call functions on the SimpleAddition contract.
If the function declarations in the interface are incorrect, the calls to the underlying contract will fail.
In the final section, we will write a few Foundry tests to check if UsingInterface can call functions on SimpleAddition.
Interfaces.t.sol

💻 The code corresponding to this page can be found on Github at Interfaces.t.sol

As usual, start by importing all the required files:

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleAddition} from "./SimpleAddition.sol";
import {UsingInterface} from "./UsingInterface.sol";

contract UsingInterface_test is Test {

}
Next, define the setup() function that sets the initial state for each test function:

    SimpleAddition public simpleAddition;
    UsingInterface public usingInterface;

    function setUp() public {
        
        simpleAddition = new SimpleAddition();
        usingInterface = new UsingInterface(address(simpleAddition));
    }
Note that we use the address of the SimpleAddition contract to initialize the UsingInterface contract. Next, let us write two test functions to check if we can change the values the state variables:

    function test_setA() public {
        usingInterface.setA(1);
        assertEq(simpleAddition.a(), 1, "Value of `a` in SimpleAddition should be 1");
    }

    function test_setB() public {
        usingInterface.setB(2);
        assertEq(simpleAddition.b(), 2, "Value of `b` in SimpleAddition should be 2");
    }
Finally, let us write test functions to check if we can call the addition functions defined in the SimpleAddition contract. We want to make sure that the

    // The values of `a` and `b` were set as 10 and 20 respectively
    // in the `SimpleAddition` contract. Thus, the sum should be 30
    // if we call the `returnSumOfStateVariables()` function without
    // changing the values of `a` and `b` first.
    function test_returnSumOfStateVariablesWithoutChange() public {
        assertEq(usingInterface.returnSumOfStateVariables(), 30, "sum of state variables should be 30");
    }

    function test_returnSumOfStateVariablesWithChange() public {
        usingInterface.setA(1);
        usingInterface.setB(2);
        assertEq(usingInterface.returnSumOfStateVariables(), 3, "sum of state variables should be 3");
    }

    function test_returnSumOfLocalVariables() public {
        assertEq(usingInterface.returnSumOfLocalVariables(5, 10), 15, "sum should be 3");
    }
Run the tests and see if they pass.
https://www.solidity-in-foundry.com/SolidityBasics/Interfaces/Interfaces_test.html
Local testing using a Mock contract
tip
VRF V2.5 SUBSCRIPTION MOCK TUTORIAL
Refer to the VRF V2.5 version of this subscription mock tutorial to learn how to test locally with VRF V2.5. To compare V2.5 and V2, refer to the migration guide.
note
YOU ARE VIEWING THE VRF V2 GUIDE - SUBSCRIPTION METHOD
Refer to the Migrating from V2 guide to find VRF V2.5 code examples for both subscription and direct funding, and to learn about the differences between V2.5 and V2. Alternatively, to learn how to request random numbers without a subscription, see the V2 direct funding method guide.
tip
SECURITY CONSIDERATIONS
Be sure to review your contracts with the security considerations in mind.
This guide explains how to test Chainlink VRF v2 on a Remix IDE sandbox blockchain environment. Note: You can reuse the same logic on another development environment, such as Hardhat or Truffle. For example, read the Hardhat Starter Kit RandomNumberConsumer unit tests.
caution
TEST ON PUBLIC TESTNETS THOROUGHLY
Even though local testing has several benefits, testing with a VRF mock covers the bare minimum of use cases. Make sure to test your consumer contract throughly on public testnets.
Benefits of local testing
Testing locally using mock contracts saves you time and resources during development. Some of the key benefits include:
Faster feedback loop: Immediate feedback on the functionality and correctness of your smart contracts. This helps you quickly identify and fix issues without waiting for transactions to be mined/validated on a testnet.
Saving your native testnet gas: Deploying and interacting with contracts requires paying gas fees. Although native testnet gas does not have any associated value, supply is limited by public faucets. Using mock contracts locally allows you to test your contracts freely without incurring any expenses.
Controlled environment: Local testing allows you to create a controlled environment where you can manipulate various parameters, such as block time and gas prices, to test your smart contracts' function as expected under different conditions.
Isolated testing: You can focus on testing individual parts of your contract, ensuring they work as intended before integrating them with other components.
Easier debugging: Because local tests run on your machine, you have better control over the debugging process. You can set breakpoints, inspect variables, and step through your code to identify and fix issues.
Comprehensive test coverage: You can create test cases to cover all possible scenarios and edge cases.
Testing logic
Complete the following tasks to test your VRF v2 consumer locally:
Deploy the VRFCoordinatorV2Mock. This contract is a mock of the VRFCoordinatorV2 contract.
Call the VRFCoordinatorV2Mock createSubscription function to create a new subscription.
Call the VRFCoordinatorV2Mock fundSubscription function to fund your newly created subscription. Note: You can fund with an arbitrary amount.
Deploy your VRF consumer contract.
Call the VRFCoordinatorV2Mock addConsumer function to add your consumer contract to your subscription.
Request random words from your consumer contract.
Call the VRFCoordinatorV2Mock fulfillRandomWords function to fulfill your consumer contract request.
Testing
Open the contracts on RemixIDE
Open VRFCoordinatorV2Mock and compile in Remix:
copy to clipboard
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
Open in Remix
What is Remix?
Open VRFv2Consumer and compile in Remix:
copy to clipboard
// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title The RandomNumberConsumerV2 contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract RandomNumberConsumerV2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant CALLBACK_GAS_LIMIT = 100000;

    // The default is 3, but you can set this higher.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant NUM_WORDS = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    event ReturnedRandomness(uint256[] randomWords);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param  - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        emit ReturnedRandomness(randomWords);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
Open in Remix
What is Remix?
Your RemixIDE file explorer should display VRFCoordinatorV2Mock.sol and VRFv2Consumer.sol:

Deploy VRFCoordinatorV2Mock
Open VRFCoordinatorV2Mock.sol.
Under DEPLOY & RUN TRANSACTIONS, select VRFCoordinatorV2Mock.

Under DEPLOY, fill in the _BASEFEE and _GASPRICELINK. These variables are used in the VRFCoordinatorV2Mock contract to represent the base fee and the gas price (in LINK tokens) for the VRF requests. You can set: _BASEFEE=100000000000000000 and _GASPRICELINK=1000000000.
Click on transact to deploy the VRFCoordinatorV2Mock contract.
Once deployed, you should see the VRFCoordinatorV2Mock contract under Deployed Contracts.

Note the address of the deployed contract.
Create and fund a subscription
Click on createSubscription to create a new subscription.
In the RemixIDE console, read your transaction decoded output to find the subscription ID. In this example, the subscription ID is 1.

Click on fundSubscription to fund your subscription. In this example, you can set the _subid to 1 (which is your newly created subscription ID) and the _amount to 1000000000000000000.
Deploy the VRF consumer contract
In the file explorer, open VRFv2Consumer.sol.
Under DEPLOY & RUN TRANSACTIONS, select RandomNumberConsumerV2.

Under DEPLOY, fill in SUBSCRIPTIONID with your subscription ID, vrfCoordinator with the deployed VRFCoordinatorV2Mock address and, KEYHASH with an arbitrary bytes32 (In this example, you can set the KEYHASH to 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc).
Click on transact to deploy the RandomNumberConsumerV2 contract.
After the consumer contract is deployed, you should see the RandomNumberConsumerV2 contract under Deployed Contracts.

Note the address of the deployed contract.
Add the consumer contract to your subscription
Under Deployed Contracts, open the functions list of your deployed VRFCoordinatorV2Mock contract.
Click on addConsumer and fill in the _subid with your subscription ID and _consumer with your deployed consumer contract address.

Click on transact.
Request random words
Under Deployed Contracts, open the functions list of your deployed RandomNumberConsumerV2 contract.
Click on requestRandomWords.

In the RemixIDE console, read your transaction logs to find the VRF request ID. In this example, the request ID is 1.

Note your request ID.
Fulfill the VRF request
Because you are testing on a local blockchain environment, you must fulfill the VRF request yourself.
Under Deployed Contracts, open the functions list of your deployed VRFCoordinatorV2Mock contract.
Click fulfillRandomWords and fill in _requestId with your VRF request ID and _consumer with your consumer contract address.

Click on transact.
Check the results
Under Deployed Contracts, open the functions list of your deployed RandomNumberConsumerV2 contract.
Click on s_requestId to display the last request ID. In this example, the output is 1.

Each time you make a VRF request, your consumer contract requests two random words. After the request is fulfilled, the two random words are stored in the s_randomWords array. You can check the stored random words by reading the two first indexes of the s_randomWords array. To do so, click on the s_randomWords function and:
Fill in the index with 0 then click on call to read the first random word.

Fill in the index with 1 then click on call to read the second random word.

Next steps
This guide demonstrated how to test a VRF v2 consumer contract on your local blockchain. We made the guide on RemixIDE for learning purposes, but you can reuse the same testing logic on another development environment, such as Truffle or Hardhat. For example, read the Hardhat Starter Kit RandomNumberConsumer unit tests.
Developer DAO Blog | Web3 Tutorials


Follow

The Developer's Guide to Chainlink VRF: Foundry Edition
The Developer's Guide to Chainlink VRF: Foundry Edition
In this article, you will learn how to build and test smart contracts powered by Chainlink's VRF service.

Priyank Gupta's photo
Priyank Gupta
·
Jun 14, 2023
·
23 min read

Fazle Rahman's photo
Priyank Gupta's photo
Arthur Andrews's photo
Flenn Franklin's photo
+7
Table of contents
What will we build?
Before we start
Setting up a dev environment with Foundry
Setting up IPFS metadata
A generic ERC1155 contract
Remappings in Foundry
What do we want Chainlink VRF for?
Creating a VRF subscription
VRF-powered randomization
A conceptual detour
Wrapping up the contract
Testing locally using the mock contract
Deploying to Mumbai
Getting your own random Patrick

Show more
Generating truly random numbers on a computer is a complex mathematical problem. However, most programming languages today have either native support for generating random numbers or come with supporting libraries that generate random numbers with an acceptable level of determinism mixed in.

While generating acceptably-random numbers is a mostly solved problem in traditional computing, it is nigh impossible to do so on blockchains.

D_D Newsletter CTA

Yes, you could hash together a bunch of block and transaction data with a keccak256 function, but that is ad-hoc at best and is definitely not production-worthy code today.

If you've been in Web3 for any reasonable amount of time, you have undoubtedly heard of Chainlink.
Chainlink is a decentralized oracle network that feeds a variety of data to blockchains in real-time so that smart contract developers can access reliable off-chain data without compromising the security of their contracts.

In this article, you will learn about Chainlink's VRF service, a powerful tool that you can use to integrate randomization into your smart contract securely.
Plus, we will do everything with Foundry, one of the market's latest smart contract development frameworks.

What will we build?

In this article, we will:

Set up a dev environment with Foundry to work with Chainlink and Openzeppelin's contracts.
Upload three images and their corresponding JSON metadata to Pinata, a pinning service for IPFS.
Set up an ERC1155 contract, without VRF, to mint multiple tokens from our limited collection of images.
Randomize the mint function by integrating Chainlink VRF into our contract.
Test our random NFT minting contract, now powered by Chainlink's VRF, using a local mock contract.
Deploy and verify our contract to the Mumbai testnet using Forge, to make it possible for anyone to mint an NFT from our contract.
Note 📝: A few months ago, Patrick Collins posted a tweet with pictures that looked like they were part of a gym photoshoot.
These are the pictures that we will be turning into NFTs on the Mumbai testnet, with permission to do so from Patrick.

I figured that hardly anything could sell harder than Patrick in a Chainlink article. Also makes for a fun project with a cool end result.

Follow along, and by the end you will be the owner of a new, shiny Patrick Collins NFT.

Before we start

This will be a no-holds-barred, technical, deep dive into Chainlink VRF. This article is, in fact, about 70% of what I originally intended to publish.

If you don't feel confident in your Solidity skills, I highly recommend you check out this full blockchain development course with Foundry on Youtube, also published by Patrick.

This is hands down the most up-to-date and in-depth course on blockchain development to exist, and you will definitely be able to follow along with the article if you could complete at least part 1 of the series.


I recommend you don't follow along with the article in the first read, primarily if you haven't used VRF before.
Instead, try to digest the concepts I have worked hard to put into simple words.

As a reward for reading through to the end, you will be able to mint yourself a Patrick Collins NFT :)

Setting up a dev environment with Foundry

Foundry is an increasingly popular smart contract development framework.

This is not an introductory course to Foundry. I recommend you check out the Foundry book for a detailed reference or this repo I made for a quick crash course.

Once you have Foundry installed, make sure all of its components are up to date using the following:


COPY

COPY
foundryup
Open a new terminal in a new directory, and initialize a new Foundry project using:


COPY

COPY
forge init
We use Chainlink and Openzeppelin's smart contract libraries as part of our code. To install Openzeppelin contracts into your Foundry project, run:


COPY

COPY
forge install Openzeppelin/openzeppelin-contracts
We don't need to install the repo containing all of Chainlink's code alongside its node binary. We can install its slimmed-down version, containing only the contracts, by running:


COPY

COPY
forge install smartcontractkit/chainlink-brownie-contracts
By default, Forge manages dependencies via git submodules, and we don't need to change this behavior (even though we can). You can find all the dependencies for this project in the lib directory.

Note 📝: Foundry is modular in design and is a collection of four different CLI tools(for now). These are Forge, Cast, Anvil, and Chisel.
In this article, I'll mainly be using Forge and Anvil.

Setting up IPFS metadata

Go to Pinata, and sign up for an account. We only need the free tier for our needs.
Gather all the images you want to tokenize into a single folder. I named Patrick's pictures 1.png, 2.png, and 3.png. I highly recommend following a simplified naming convention.
Upload all these images to Pinata as a single folder. This means you'll receive a single content identifier (CID). An individual image can now be accessed as ipfs://CID/1.png. My folder of images can be accessed via this link.
Next, we will create three individual JSON files to store Opensea-compatible metadata. Again we'll name them as 1.json, 2.json, and 3.json. You can read about Opensea's metadata standards in detail on their docs. For now, this is what 1.json will look like. You can check out all three of the JSON files through this IPFS URL.

COPY

COPY
  {
   "name": "Patrick in the gym #1",
   "description": "Call the mint function from this contract to get one of the three images from Patrick's gym photoshoot. This contract has a randomized mint function powered by Chainlink's VRF service.",
   "image": "ipfs://QmQCRiKqzirEUBkjpoYJBKCBG4ynpknAjqH4Cp6rLTSTik/1.png",
   "edition": 1,
   "date": 1685971561,
   "attributes": [
     {
       "trait_type": "Probability of getting this image.",
       "value": "1%"
     }
   ]
 }
The critical thing is to note the probability value. This means we want a minter to have only a 1% to get 1.png. These values are 33% and 66% for the second and third images and will be enforced via Chainlink VRF.
Finally, we upload these 3 JSON files to Pinata, again, as part of a single folder. This gives us a single CID to access all 3 of these files. Opensea only uses JSON metadata to display the NFT image and associated properties.
A generic ERC1155 contract

Pro Tip 💡: Before moving further, I highly recommend you know the differences between the 721 and 1155 NFT standards.

Before adding randomization to our smart contract, let us set up a generic ERC1155 smart contract.

Go to Openzeppelin Contracts Wizard and set up a boilerplate ERC1155 contract with the following configurations
Openzeppelin Contracts Wizard
Note 📝: The IPFS metadata for our collection can be accessed as ipfs://CID/{1 or or 2 or 3}.json. These numbers will also be the token IDs of our pictures. Hence, we pass the generic CID of our metadata to the smart contract like this:

"ipfs://QmXN7twhiJF7pSttkvqxfok9o5p1QWJeCbwRTZvZ5RCzvz/{id}.json"

Any instance of {id} will be replaced by the tokenID by clients like Opensea.

Inside the src directory at the root of your Foundry project, create a file named nft.sol. Paste the code as it is inside.
We make a few changes.
I removed the mintBatch function because I don't want anyone to have more than 1 NFT from this contract.
Added a public string called name initialized with this value: Patrick Through VRF. We need to expose a public string called name for Opensea to be able to give a name to our collection. This variable is created automatically in the ERC721 standard but not in the ERC1155 standard.
Next, I created a mapping called _minted that will keep track of all the addresses that have minted an NFT already minted an NFT.
After this, I hardcoded all the parameters of the mint function except the tokenID.
Lastly, I added a simple event that will be emitted every time our contract mints an NFT.
This is what our contract looks like at this point.


COPY

COPY
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract PatrickInTheGym is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {

    mapping(address => bool) public _minted;
    string public name = "Patrick Through VRF";

    event TokenMinted(address indexed account, uint256 indexed id);

    constructor() ERC1155("ipfs://QmXN7twhiJF7pSttkvqxfok9o5p1QWJeCbwRTZvZ5RCzvz/{id}.json") {}

    function mint(uint256 id)
        public
    {
        require(!_minted[msg.sender], "You can only mint once");
        _minted[msg.sender] = true;
        _mint(msg.sender, id, 1, "");
        emit TokenMinted(msg.sender, id);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
This contract will allow anyone to call the mint function from our contract exactly once, and that person can choose the image they want by passing in the tokenID of their choice.

Keep this in mind. I'll expand on this below.

Remappings in Foundry

Let us compile our contract to make sure everything works smoothly up to this point. To compile contracts in Foundry, run:


COPY

COPY
forge build
But Forge won't be able to compile our contract right away since it doesn't understand the format our import statements are using. More precisely, Forge has no idea what "@openzeppelin" is.

Run the following command in your terminal:


COPY

COPY
forge remappings > remappings.txt
This command will create a new file named remappings.txt at the root of your project and will fill it with some remappings that Forge has automatically deduced for you. For now, make sure you add this line to the remappings file.


COPY

COPY
@openzeppelin/=lib/openzeppelin-contracts/
Save the changes in the remappings file, and rerun the build command. This time our contract should compile successfully.

What do we want Chainlink VRF for?

Our contract allows anyone to mint one NFT from our collection by passing a tokenID of their choice. We want to integrate Chainlink VRF into our contract so that the mint function randomly mints one of the three pictures with varying probability levels.


Here's the solution I came up with.

Ask VRF to generate a random number between 1 and 100, including both bounds.
If the returned number is 100, mint an NFT with the tokenID set to 1.
If the number returned is divisible by 3, mint an NFT with the tokenID set to 2.
Else, mint an NFT with the tokenID set to 3.
Note 📝: If you can develop a more efficient solution, comment below.

Creating a VRF subscription

Chainlink VRF currently offers us two methods for requesting randomness:

Direct Funding: This method entails maintaining an appropriate balance of LINK tokens in the consuming contract to pay for each randomness request.
Subscription: This method creates a particular 'subscription' containing the required LINK tokens. This account can then be used to fund multiple consuming contracts as per the owner's wishes.
We will go with the Subscription method in this tutorial.

Go to faucets.chain.link and request a few LINK tokens to an EOA.
Go to vrf.chain.link and create a new subscription on the Mumbai testnet.
The subscription id is what we will need soon.
Once your subscription has been created, add some LINK tokens.
We will add a consuming contract to our subscription once we have deployed one.
VRF-powered randomization

Create a new file named nftVRF.sol inside the src directory.

Get ready. The real stuff starts now.


First, we need to import some Chainlink dependencies into our contract. Add these imports to nftVRF.sol


COPY

COPY
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
You might need to configure Chainlink imports the same way as before in the remappings file.

Pro-tip 💡: Forge installed an outdated version of the Chainlink contracts repo for me. I don't understand why that happened.
If you face the same issue, run forge update lib/chainlink-brownie-contracts to update this library.

The VRFCoordinatorV2Interface is an interface used to interact with the VRFCoordinator contract deployed on the chain you are using. You can check out the coordinator contract for Mumbai testnet here.
An interface in Solidity is a collection of function declarations (NOT definitions) marked external.
Interfaces are useful when your smart contract needs to interact with another smart contract, and you only need to know the function signatures of the other contract.
To send a randomness request to Chainlink, we call the requestRandomWords() on this contract.
The subscription you created on vrf.chain.link is just a UI that calls the createSubscription() function on the coordinator contract.
Please check out the interface code for a better understanding.
The VRFConsumerBaseV2 is an abstract contract. The Chainlink Coordinator requires us to inherit this contract as a parent and implement a function named fulfillRandomWords().
The Coordinator then calls the fulfillRandomWords() once the random values are generated.
Note 📝: An abstract contract is like a regular contract, but it's not fully implemented. It may have some functions without a body (i.e., without implementation). A contract with at least one function without implementation is considered abstract.

Declare the main contract while importing all the dependencies:


COPY

COPY
contract PatrickInTheGym is ERC1155,
                            ERC1155Burnable, 
                            Ownable, 
                            ERC1155Supply, 
                            VRFConsumerBaseV2
{
}
You will immediately see the whole thing go red in errors. This is because the VRFConsumerBaseV2 contract requires a constructor to be initialized, and our contract won't compile till we provide constructor arguments for all base contracts.

Let us start configuring all the variables we need to call the requestRandomWords() function from the Coordinator contract. Take a look at all these variables:


COPY

COPY
//Chainlink Variables
VRFCoordinatorV2Interface private immutable CoordinatorInterface;
uint64 private immutable _subscriptionId;
address private immutable _vrfCoordinatorV2Address;
bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
uint32 callbackGasLimit = 200000;
uint16 blockConfirmations = 10;
uint32 numWords = 1;
The CoordinatorInterface is simply a new instance of the VRFCoordinatorV2Interface . This instance will be initialized in the constructor.
Subscription ID: The unique ID for your subscription that holds the LINK to fund your contract's Randomness request.
This value must be initialized in the constructor.
Coordinator V2 Address: The address of the Chainlink VRF Coordinator contract on that particular chain.
Key Hash/Gas Lane: This hash value represents the maximum gas price you are willing to pay. Mainnets supported by Chainlink VRF typically have multiple supported 'gas lanes'; the Mumbai testnet, however, has only one.
You can check out the value on Chainlink's documentation.
Callback Gas Limit: This value specifies the maximum amount of gas the Coordinator contract must use to call the fulfillRandomWords() to return the random values.
Block Confirmations: This value sets the number of blocks the Coordinator will wait for before sending back our random values. The greater this value is, the more secure the generated random number is. The minimum and maximum block confirmations are specified for each network in Chainlink's documentation.
Number of words: The number of random values to get back in one request. We will call back for one word per request.
Add those values right below the contract declaration.

A conceptual detour

Let us take a detour to explore the new workflow more carefully. The mint function will undergo significant changes compared to the generic 1155 contract, and it is vital to understand the differences.

Here's what will happen in the new contract:

The user calls a function named mint() on the main contract, but this won't directly mint them an NFT. Instead, this mint function will internally call the requestRandomWords() that tells the VRF Coordinator:
"Hey dude, I want a random number. Please wait for 10 blocks and then give me a random number".
Invoking this function triggers an event called RandomWordsRequested from the Coordinator contract; an off-chain VRF node picks that up.
The VRF node will wait ten blocks (as we specified) before returning a random number to the Coordinator contract.
The Coordinator will then call the fulfillRandomWords() function from our contract and execute whatever logic is included.
We will mint NFTs from inside this function.
Note 📝: Let me repeat this. The user will only call the mint() function, which triggers the requestRandomWords() function.
The coordinator contract calls the fulfillRandomWords() function, which makes it the 'Callback Function'.

Take a look at this rough diagram. This will become clearer as we write the rest of the code.


D_D Newsletter CTA
Wrapping up the contract

Let us finally get our constructor set up. We need to do two things:

Pass our subscription id as a constructor parameter to the main contract.
Initialize the VRFConsumerBaseV2 contract's constructor by passing the Coordinator's address.
This is how our constructor will look like:


COPY

COPY
constructor(uint64 subscriptionId, address vrfCoordinatorV2Address)
ERC1155("ipfs://QmXN7twhiJF7pSttkvqxfok9o5p1QWJeCbwRTZvZ5RCzvz/{id}.json")
VRFConsumerBaseV2(vrfCoordinatorV2Address)
{
     _subscriptionId = subscriptionId;
     _vrfCoordinatorV2Address= vrfCoordinatorV2Address;
     CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
}
Note 📝: I also created a new instance of the Coordinator contract called the CoordinatorInterface . This will make it simpler to call functions using the interface.

Next, I will declare some state variables required for the contract. This is what our contract looks like right now.


COPY

COPY
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract PatrickInTheGym is
    ERC1155,
    ERC1155Burnable,
    Ownable,
    ERC1155Supply,
    VRFConsumerBaseV2
{
    //Contract Variables and events
    mapping(address => bool) public _minted;
    string public name = "Patrick Through VRF";
    mapping(uint256 => address) public _requestIdToMinter;
    event RequestInitalized(uint256 indexed requestId, address indexed minter);
    event NftMinted(uint256 indexed tokenID, address indexed minter);

    //Chainlink Variables
    VRFCoordinatorV2Interface private immutable CoordinatorInterface;
    uint64 private immutable _subscriptionId;
    address private immutable _vrfCoordinatorV2Address;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2Address
    )
        ERC1155("ipfs://QmXN7twhiJF7pSttkvqxfok9o5p1QWJeCbwRTZvZ5RCzvz/{id}.json")
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
    {
        _subscriptionId = subscriptionId;
        _vrfCoordinatorV2Address= vrfCoordinatorV2Address;
        CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
    }
}
Create a new function mint() right below the constructor as follows:


COPY

COPY
 function mint() public returns (uint256 requestId)
 {
        require(!_minted[msg.sender], "You can only mint once");

        //Calling requestRandomWords from the coordinator contract
        requestId = CoordinatorInterface.requestRandomWords(
            keyHash,
            _subscriptionId,
            blockConfirmations,
            callbackGasLimit,
            numWords
        );

        // map the caller to their respective requestIDs.
        _requestIdToMinter[requestId] = msg.sender;

        // emit an event
        emit RequestInitalized(requestId, msg.sender);
    }
The function can only be called by an address that doesn't already hold an NFT from our contract.
We call the requestRandomWords() function from the Coordinator contract here. The function returns a unique variable of type uint256 that we will store as the requestID.
The calling of the requestRandomWords() function will automatically start the random number generation off-chain process.
Note 📝: Why do we use the _requestIdToMinter mapping?

Because many people worldwide may simultaneously call the mint function. In that case, it is helpful to assign requestIDs to the minters since we can keep track of the arriving results.

Create a fulfillRandomWords() function right below the mint() function like this:


COPY

COPY
function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // get the minter address
        address minter = _requestIdToMinter[requestId];

        // To generate a random number between 1 and 100 inclusive
        uint256 randomNumber = (randomWords[0] % 100) + 1;

        uint256 tokenId;

        //manipulate the random number to get the tokenId with a variable probability
        if(randomNumber == 100){
            tokenId = 1;
        } else if(randomNumber % 3 == 0) {
            tokenId = 2;
        } else {
            tokenId = 3;
        }

        // Updating the mapping
        _minted[minter] = true;

        // Finally mint the token
        _mint(minter, tokenId, 1, "");

        // emit an event
        emit NftMinted(tokenId, minter);
    }
The piece of code above will be called by the Coordinator contract whenever it wants to return the results of a successful randomness request.

This function, whenever triggered, will mint a random NFT to someone who called the mint() function from our contract.

Lastly, add in the _beforeTokenTransfer function from the ERC1155 standard.


COPY

COPY

  // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
This is what the contract finally looks like:


COPY

COPY
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract PatrickInTheGym is
    ERC1155,
    ERC1155Burnable,
    Ownable,
    ERC1155Supply,
    VRFConsumerBaseV2
{
    //Contract Variables and events
    mapping(address => bool) public _minted;
    string public name = "Patrick Through VRF";
    mapping(uint256 => address) public _requestIdToMinter;
    event RequestInitalized(uint256 indexed requestId, address indexed minter);
    event NftMinted(uint256 indexed tokenID, address indexed minter);

    //Chainlink Variables
    VRFCoordinatorV2Interface private immutable CoordinatorInterface;
    uint64 private immutable _subscriptionId;
    address private immutable _vrfCoordinatorV2Address;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 10;
    uint32 numWords = 1;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2Address
    )
        ERC1155("ipfs://QmXN7twhiJF7pSttkvqxfok9o5p1QWJeCbwRTZvZ5RCzvz/{id}.json")
        VRFConsumerBaseV2(vrfCoordinatorV2Address)
    {
        _subscriptionId = subscriptionId;
        _vrfCoordinatorV2Address= vrfCoordinatorV2Address;
        CoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
    }

    function mint() public returns (uint256 requestId) {
        require(!_minted[msg.sender], "You can only mint once");

        //Calling requestRandomWords from the coordinator contract
        requestId = CoordinatorInterface.requestRandomWords(
            keyHash,
            _subscriptionId,
            blockConfirmations,
            callbackGasLimit,
            numWords
        );

        // map the caller to their respective requestIDs.
        _requestIdToMinter[requestId] = msg.sender;

        // emit an event
        emit RequestInitalized(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // get the minter address
        address minter = _requestIdToMinter[requestId];

        // To generate a random number between 1 and 100 inclusive
        uint256 randomNumber = (randomWords[0] % 100) + 1;

        uint256 tokenId;

        //manipulate the random number to get the tokenId with a variable probability
        if(randomNumber == 100){
            tokenId = 1;
        } else if(randomNumber % 3 == 0) {
            tokenId = 2;
        } else {
            tokenId = 3;
        }

        // Updating the mapping
        _minted[minter] = true;

        // Finally mint the token
        _mint(minter, tokenId, 1, "");

        // emit an event
        emit NftMinted(tokenId, minter);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
Run forge build to check for any immediate errors. The contract should compile successfully.

Pro Tip 💡: There might be scenarios where you may want to change values like keyHash, numWords, or blockConfirmations. It is a good idea to expose these variables through a public function guarded by an onlyOwner modifier so that you can configure these values if needed.

Let us move on to testing the contract with Forge's testing utilities.

Testing locally using the mock contract

Chainlink provides us with a VRFCoordinatorV2Mock contract for testing purposes. It simulates the behavior of the actual VRFCoordinatorV2 contract, which allows us to test VRF-powered contracts locally.

Create a file named vrfTest1.t.sol inside the' test' directory.

Set up the imports required for testing:


COPY

COPY
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/nftVRF.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
Initialize the test contract like this:


COPY

COPY
contract PatrickInTheGymTest is Test {

}
Declare some state variables for the test contract:


COPY

COPY
    //Creating instances of the main contract
    //and the mock contract
    PatrickInTheGym public patrickInTheGym;
    VRFCoordinatorV2Mock public mock;

    //To keep track of the number of NFTs
    //of each tokenID
    mapping(uint256 => uint256) supplytracker;

    //This is a shorthand used to represent the full address
    // address(1) == 0x0000000000000000000000000000000000000001
    address alpha = address(1);
Some concepts about testing in Foundry:

If the name of any solidity function in your directory starts with the string "test", Forge will treat it as a test function. Therefore, testVRF(), is a valid name for a test function, but VRFtest() is not.
Forge runs all test functions in a new instance of the EVM by default. This means the state changes due to one test function have no bearing on the results of the next one.
setup() is a special function that can be included in your Foundry testing suite. This function is executed by Forge every time before running a new test function.
We will use the setup() function to 'set up' the blockchain state we require to test our randomized minting function.
Define a new function named setup() below the state variables like this:


COPY

COPY
    function setUp() public {
        //Can ignore this. Just sets some base values
        // In real-world scenarios, you won't be deciding the 
        //constructor values of the coordinator contract anyways
        mock = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);

        //Creating a new subscription through account 0x1
        //Prank cheatcode explained below the code snippet
        vm.prank(alpha);
        uint64 subId = mock.createSubscription();

        //funding the subscription with 1000 LINK
        mock.fundSubscription(subId, 1000000000000000000000);

        //Creating a new instance of the main consumer contract
        patrickInTheGym = new PatrickInTheGym(subId, address(mock));

        //Adding the consumer contract to the subscription
        //Only owner of subscription can add consumers
        vm.prank(alpha);
        mock.addConsumer(subId, address(patrickInTheGym));
    }
Note 📝: The Prank cheat code is a convenient way to 'impersonate' a call to the blockchain from a specific address.

The call right below the Prank cheatcode will be executed with the specified address being set as msg.sender.

Now finally, create a function named testRandomness() as follows:


COPY

COPY
function testRandomness() public {

        for (uint i = 1; i <= 1000; i++) {

        //Creating a random address using the 
        //variable {i}
        //Useful to call the mint function from a 100
        //different addresses
        address addr = address(bytes20(uint160(i)));
        vm.prank(addr);
        uint requestID = patrickInTheGym.mint();

        //Have to impersonate the VRFCoordinatorV2Mock contract
        //since only the VRFCoordinatorV2Mock contract 
        //can call the fulfillRandomWords function
        vm.prank(address(mock));
        mock.fulfillRandomWords(requestID,address(patrickInTheGym));
        }

        //Calling the total supply function on all tokenIDs
        //to get a final tally, before logging the values.
        supplytracker[1] = patrickInTheGym.totalSupply(1);
        supplytracker[2] = patrickInTheGym.totalSupply(2);
        supplytracker[3] = patrickInTheGym.totalSupply(3);

        console2.log("Supply with tokenID 1 is " , supplytracker[1]);
        console2.log("Supply with tokenID 2 is " , supplytracker[2]);
        console2.log("Supply with tokenID 3 is " , supplytracker[3]);
    }
You can run the test file using this command:


COPY

COPY
forge test --match-path test/vrfTest1.t.sol -vvvvv
Pro Tip 💡: You can adjust the verbosity levels in your terminal by configuring the '-v' flag. You can read more about this on Foundry book.

This is what I get back in the terminal if I run the for loop 1000 times:


As you can see, the percentages align with what we want.
Please note that a 'test' function passes only if it clears all the required conditions. We did not set any conditions for our test function to fail.
This testing phase was a crude way of checking whether our VRF randomness works.
Sad Note 😔: I wanted to include a full-blown section on Invariant testing.
The idea was to leverage foundry-chainlink-toolkit to write a much more wholesome testing suite.

This project is designed to be used with Forge to spin up a local Chainlink node quickly. However, I couldn't set up the node despite my best efforts.
I will write part 2 of this tutorial as soon as possible.

Deploying to Mumbai

Since I couldn't give you a cool tutorial on invariant testing with a local Chainlink node, let us move on to deploying and verifying our contract.

At the root of your Foundry project, create a .env file. Fill the env file with these values:


COPY

COPY
RPC_URL=
PRIVATE_KEY=
POLYGONSCAN_API_KEY=
You can get an RPC URL from services like Alchemy, Chainstack, or Quicknode. You can also use a public RPC URL if you so wish.
Use a private key with some MATIC tokens on the Mumbai testnet.
Get a Polygonscan API key. A key from the mainnet explorer will work on Mumbai as well.
With all the values filled, save the .env file. Run this command in the terminal to source these env variables to the terminal:


COPY

COPY
source .env
We will create a deployment script to deploy our contract to the blockchain.

Create a file named nftVRF.s.sol inside the script folder. Set up the imports like this:


COPY

COPY
pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "../src/nftVRF.sol";
Create a new contract that inherits Scripts.sol that Forge provides us:


COPY

COPY
contract PatrickInTheGymDeploy is Script {
}
Now fill the contract like this:


COPY

COPY
    function run() public {

        //Forge can read private key directly from the env file
        uint PrivateKey = vm.envUint("PRIVATE_KEY");

        //This cheatcode will broadcast all included transactions
        //on chain
        vm.startBroadcast(PrivateKey);

        //Your subscription id will be different
        //but the Coordinator address will remain the same
        //Unless you're not deploying on Mumbai
        PatrickInTheGym patrickInTheGym = new PatrickInTheGym(5125, 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);

        vm.stopBroadcast();
    }
Scripts are executed inside the run() function by default.
We can deploy our contract to the blockchain by creating a new instance within the Broadcast() cheat codes.
Save the file.
To execute the script, run this command in the terminal:


COPY

COPY
forge script script/nftVRF.s.sol:PatrickInTheGymDeploy \
--rpc-url $RPC_URL \
--broadcast -vvvv
Forge will return a contract address in the terminal. Open the address in Mumbai Explorer.

To verify this contract, run this command:

Note 📝: I configured my compiler version to 0.8.17 in the toml file. The rest of the values are default.


COPY

COPY
forge verify-contract <YOUR_SMART_CONTRACT_ADDRESS> \
--chain-id 80001 \
--num-of-optimizations 200 \
--watch --compiler-version v0.8.17+commit.8df45f5f \
--constructor-args $(cast abi-encode "constructor(uint64, address)" 5125 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
src/nftVRF.sol:PatrickInTheGym \
--etherscan-api-key $POLYGONSCAN_API_KEY
D_D Newsletter CTA

Getting your own random Patrick

The contract is deployed on the Mumbai testnet and is verified.

Just go to the link to get your random Patrick and call the mint function. As you'll notice, you have no power of choosing the tokenID, which was the whole point.
You can check out the whole collection on Opensea.
As of now, nobody has been able to mint the tokenID 1.


A confession on Verification: I have verified contracts on-chain using Forge many times before, but no matter how much I tried, I couldn't verify the contract this time.
I have NO IDEA what I am doing wrong.
I deployed the exact same contract to Mumbai through REMIX and verified it from there.
Please feel free to enlighten me on what I am doing wrong if you can figure it out.


53

1



NFT
Solidity
Blockchain
Web3
Programming Blogs
Written by


Priyank Gupta
Priyank Gupta
I love new people and I love new technologies. Trying to find my footing in the Web3 industry, hoping to become a better programmer and a more consistent shipper. Part-time Rustacean 🦀

Follow
Published on


Developer DAO Blog | Web3 Tutorials
Developer DAO Blog | Web3 Tutorials
The Developer DAO blog is an entirely Member-driven publication. We publish technical tutorials to help readers learn how to become a web3 developer, Member stories and the occasional opinion piece.

Follow
 
MORE ARTICLES


Ϗ's photo
Ϗ
Building on Bitcoin Layers With the Hiro Platform
Building on Bitcoin Layers With the Hiro Platform
Bitcoin is the highest-valued token on the planet, but building on the Bitcoin network was a hassle …

Ϗ's photo
Ϗ
Comparing Solidity With Clarity
Comparing Solidity With Clarity
Writing smart contracts for Bitcoin was limited in the past, but with Stacks, this changed. Its Clar…

Osikhena Oshomah's photo
Osikhena Oshomah
Creating a Token-Gated Web Page With Clarity
Creating a Token-Gated Web Page With Clarity
This tutorial shows how to create a token-gated website using Clarity as the smart contract language…
Developer DAO Blog | Web3 Tutorials
©2024 Developer DAO Blog | Web3 Tutorials
Archive
·
Privacy policy
·
Terms
Powered by Hashnode - Build your developer hub.
Start your blog
Create docs
Based on the provided documents, I'll create a comprehensive summary of Chainlink VRF:

Chainlink VRF (Verifiable Random Function) is a cryptographically secure random number generation service for smart contracts. Unlike traditional RNG solutions that rely on block data or timestamps which can be manipulated, Chainlink VRF provides provably fair and verifiable randomness.

Key VRF Concepts:
- Random number requests are fulfilled through a two-transaction process
- First transaction requests randomness from Chainlink network
- Second transaction delivers verified random number back to requesting contract  
- Randomness verified cryptographically using VRF coordinator contract
- Two payment models: Direct funding with LINK tokens or subscription-based
- Subscription model allows funding multiple consumer contracts from single subscription
- Each request costs LINK tokens based on gas prices and callback gas limits

Implementation Requirements:
- Contract must inherit VRFConsumerBaseV2
- Must implement fulfillRandomWords() callback function
- Must interface with VRFCoordinatorV2Interface 
- Need subscription ID from VRF subscription manager
- Need coordinator contract address for network
- Need key hash (gas lane) for desired gas price tier
- Must configure callback gas limit and minimum confirmations
- Must handle async nature of request/response pattern

Core Components:
- VRF Coordinator contract: Manages requests and verification
- VRF Consumer contract: Requests and receives random numbers
- VRF Node: Generates random numbers and proofs off-chain
- LINK token: Used for payment and security
- Subscription Manager: Handles subscription billing

Best Practices:
- Always test thoroughly with VRFCoordinatorV2Mock first
- Cache subscription ID and coordinator address as immutable
- Handle multiple pending requests with request ID mapping
- Set appropriate block confirmation count for security needs
- Calculate adequate callback gas limits based on usage
- Use subscription manager UI to fund and manage consumers
- Consider gas costs of randomness-dependent logic
- Implement request batching for multiple random numbers
- Add appropriate access controls on request functions
- Emit events for request and fulfillment tracking

Testing Approach:
- Use VRFCoordinatorV2Mock contract for local testing
- Mock coordinator requires manual fulfillment calls
- Test with various block confirmation settings
- Verify randomness distribution over many samples
- Test subscription management functionality
- Test request ID tracking and fulfillment handling
- Simulate concurrent requests and fulfillments
- Test error cases and gas limit scenarios
- Use foundry for comprehensive testing suite

Security Considerations:
- Random numbers are predictable until confirmed on-chain
- Miners can influence block data-based randomness
- Users could grief system by front-running requests
- Need adequate LINK funding for all expected requests
- Must handle coordinator contract upgrades
- Should implement request rate limiting
- Consider economic incentives for manipulation

Integration Steps:
1. Create VRF subscription in subscription manager
2. Fund subscription with LINK tokens
3. Deploy consumer contract inheriting VRFConsumerBaseV2
4. Add consumer contract to subscription whitelist
5. Request random numbers via coordinator interface
6. Handle random number delivery in fulfillment callback
7. Monitor subscription balance and request status
8. Maintain adequate subscription funding

Common Gotchas:
- Insufficient callback gas limits
- Unhandled revert cases in fulfillment logic
- Missing request ID tracking
- Inadequate subscription funding
- Front-running vulnerabilities in usage
- High gas costs from inefficient fulfillment code
- Race conditions in multi-request scenarios
- Incorrect coordinator contract addresses

This system provides cryptographically secure randomness but requires careful implementation to handle the asynchronous nature of requests and various edge cases around gas limits, funding, and concurrent usage. Proper testing with mock contracts and thorough security review is essential before production deployment.