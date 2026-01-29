import Script from "next/script";

export default function Checkout() {

  const payRazorpay = () => {
    const options = {
      key: process.env.NEXT_PUBLIC_RAZORPAY_KEY,
      amount: 19900,
      currency: "INR",
      name: "Calorie App",
      description: "Premium",
      notes: {
        user_id: new URLSearchParams(window.location.search).get("uid")
      },
      handler: function () {
        window.location.href = "/success";
      }
    };

    const rzp = new window.Razorpay(options);
    rzp.open();
  };

  return (
    <div style={{ padding: 40 }}>
      <h1>Checkout</h1>

      {/* Razorpay */}
      <Script src="https://checkout.razorpay.com/v1/checkout.js" />
      <button onClick={payRazorpay}>
        Pay ₹199 (India)
      </button>

      <hr />

      {/* PayPal */}
      <Script
        src={`https://www.paypal.com/sdk/js?client-id=${process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID}&currency=USD`}
      />

      <div id="paypal-button-container"></div>

      <Script
        dangerouslySetInnerHTML={{
          __html: `
          paypal.Buttons({
            createOrder: function(data, actions) {
              return actions.order.create({
                purchase_units: [{
                  amount: { value: '4.99' }
                }]
              });
            },
            onApprove: function(data, actions) {
              return actions.order.capture().then(function() {
                window.location.href = '/success';
              });
            }
          }).render('#paypal-button-container');
        `
        }}
      />
    </div>
  );
}