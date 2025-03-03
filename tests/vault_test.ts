import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new vault with metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("vault", "create-vault", 
        [types.none(), types.uint(2), types.some(types.ascii("Test Vault"))], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    // Try creating duplicate vault
    let block2 = chain.mineBlock([
      Tx.contractCall("vault", "create-vault", 
        [types.none(), types.uint(2), types.none()], 
        wallet_1.address
      )
    ]);
    assertEquals(block2.receipts[0].result.expectErr(), 'u101');
  },
});

Clarinet.test({
  name: "Can deposit and withdraw STX",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("vault", "create-vault",
        [types.none(), types.uint(1), types.none()],
        wallet_1.address
      ),
      Tx.contractCall("vault", "deposit",
        [types.uint(1000)],
        wallet_1.address
      ),
      Tx.contractCall("vault", "withdraw",
        [types.uint(500)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 3);
    assertEquals(block.receipts[1].result.expectOk(), true);
    assertEquals(block.receipts[2].result.expectOk(), true);
    
    // Try invalid amount
    let block2 = chain.mineBlock([
      Tx.contractCall("vault", "deposit",
        [types.uint(0)],
        wallet_1.address
      )
    ]);
    assertEquals(block2.receipts[0].result.expectErr(), 'u106');
  },
});

Clarinet.test({
  name: "Cannot withdraw when time-locked",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("vault", "create-vault",
        [types.none(), types.uint(1), types.none()],
        wallet_1.address
      ),
      Tx.contractCall("vault", "deposit",
        [types.uint(1000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[0].result.expectOk(), true);
    assertEquals(block.receipts[1].result.expectOk(), true);
  },
});
