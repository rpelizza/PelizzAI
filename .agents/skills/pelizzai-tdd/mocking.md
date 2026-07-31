# When to Mock

Mock **only at system boundaries**:

- External APIs (payment, e-mail, etc.)
- Databases (sometimes — prefer a test database)
- Time/randomness
- File system (sometimes)

Do not mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Take external dependencies as parameters instead of creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
	return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
	const client = new StripeClient(process.env.STRIPE_KEY);
	return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: each function is independently mockable
const api = {
	getUser: (id) => fetch(`/users/${id}`),
	getOrders: (userId) => fetch(`/users/${userId}/orders`),
	createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: mocking requires conditional logic inside the mock
const api = {
	fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:

- Each mock returns a specific shape
- No conditional logic in test setup
- It is easier to see which endpoints a test exercises
- Type safety per endpoint
