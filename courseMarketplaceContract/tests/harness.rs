use fuels::{prelude::*, types::{ContractId, Bits256}};

// Load abi from json
abigen!(Contract(
    name = "courseMarketplaceContract",
    abi = "out/debug/courseMarketplaceContract-abi.json"
));

async fn get_contract_instance() -> (courseMarketplaceContract<WalletUnlocked>, ContractId) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await
    .unwrap();
    let wallet = wallets.pop().unwrap();

    let id = Contract::load_from(
        "./out/debug/courseMarketplaceContract.bin",
        LoadConfiguration::default(),
    )
    .unwrap()
    .deploy(&wallet, TxPolicies::default())
    .await
    .unwrap();

    let instance = courseMarketplaceContract::new(id.clone(), wallet);

    (instance, id.into())
}

#[tokio::test]
async fn can_purchase_course() {
    let (_instance, _id) = get_contract_instance().await;

    let call_params = CallParameters::new(1_000_000, AssetId::base(), 1_000_000);

    let course_id: Bits256 = Bits256([0xb1, 0x0d, 0xa2, 0x32, 0xa7, 0x6e, 0xae, 0xb6,
        0x87, 0x9f, 0x1b, 0x09, 0xfb, 0xee, 0x93, 0x08,
        0xdf, 0x70, 0x9b, 0x2a, 0xc7, 0x3f, 0xba, 0xeb,
        0xba, 0x28, 0xca, 0x8d, 0x61, 0x29, 0x51, 0x1c]);

    let proof: Bits256 = Bits256([0xc8, 0x55, 0xb4, 0x44, 0x4f, 0x7e, 0xa1, 0x81,
    0x83, 0x97, 0x95, 0x43, 0x40, 0x35, 0x78, 0x65,
    0x19, 0x8e, 0x56, 0xc1, 0xb2, 0x74, 0x20, 0xe9,
    0xab, 0x92, 0x03, 0x63, 0xd4, 0xd8, 0x39, 0xad]);

    let result = _instance.methods()
        .purchase_course(course_id, proof).call_params(call_params).unwrap().call().await.unwrap();

    println!("{:#?}", result);
    // Now you have an instance of your contract you can use to test each function
}
