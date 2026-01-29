export default function Upgrade() {
  return (
    <div style={{ padding: 40 }}>
      <h1>Premium Plan</h1>
      <ul>
        <li>Adaptive calorie engine</li>
        <li>Packaged food label tracking</li>
        <li>Hidden sugar alerts</li>
        <li>Weekly body reports</li>
      </ul>

      <a href="/checkout?plan=premium">
        Go to Checkout
      </a>
    </div>
  );
}