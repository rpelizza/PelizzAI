# Good and Bad Tests

## Good Tests

**Integration style**: Test through real interfaces, not mocks of internals.

```typescript
// GOOD: Tests the observable behavior
test('user checks out with a valid cart', async () => {
	const cart = createCart();
	cart.add(product);
	const result = await checkout(cart, paymentMethod);
	expect(result.status).toBe('confirmed');
});
```

Characteristics:

- Tests behaviors that matter to users/callers
- Uses only the public API
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test('checkout calls paymentService.process', async () => {
	const processSpy = jest.spyOn(paymentService, 'process');
	await checkout(cart);
	expect(processSpy).toHaveBeenCalledWith(cart.total);
});
```

Warning signs:

- Mocking internal collaborators
- Testing private methods
- Asserting call counts/order
- The test breaks on a refactor with no behavior change
- The test name describes HOW, not WHAT
- Verifying through external means instead of the interface

```typescript
// BAD: Bypasses the interface to verify
test('createUser writes to the database', async () => {
	await createUser({ name: 'Alice' });
	const row = await db.query('SELECT * FROM users WHERE name = ?', ['Alice']);
	expect(row).toBeDefined();
});

// GOOD: Verifies through the interface
test('createUser makes the user retrievable', async () => {
	const user = await createUser({ name: 'Alice' });
	const retrieved = await getUser(user.id);
	expect(retrieved.name).toBe('Alice');
});
```

## Anti-pattern: Tautological Test

The expected value must come from a **source independent** of the implementation: a known literal, a hand-worked example, the spec. If the expected value is computed by the same logic under test (or copied from the code's current output), the test only proves that the code does what the code does — and passes forever, bug included.

```typescript
// BAD: expected value derived from the very logic under test
test('computes the discounted total', () => {
	const expected = applyDiscount(subtotal(cart), coupon); // same logic!
	expect(computeTotal(cart, coupon)).toBe(expected);
});

// GOOD: expected value from an independent source (worked example: 100 − 10% = 90)
test('computes the discounted total', () => {
	expect(computeTotal(cartOf100, tenPercentCoupon)).toBe(90);
});
```
