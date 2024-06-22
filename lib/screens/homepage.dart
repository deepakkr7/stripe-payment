import 'package:flutter/material.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:stripe_payment/stripe_payment.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    StripePayment.setOptions(StripeOptions(
      publishableKey: "YOUR_PUBLISHABLE_KEY",
      merchantId: "Test",
      androidPayMode: 'test',
    ));
  }

  void _processPayment() async{
    if (_formKey.currentState!.validate()) {
          final card = CreditCard(
            number: _cardNumberController.text,
            expMonth: int.parse(_expiryDateController.text.split('/')[0]),
            expYear: int.parse(_expiryDateController.text.split('/')[1]),
            cvc: _cvvController.text,
            name: _cardHolderNameController.text,
          );

          try {
            final paymentMethod = await StripePayment.createPaymentMethod(
              PaymentMethodRequest(card: card),
            );

            HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
            final response = await callable.call(<String, dynamic>{
              'amount': 1000, // amount in cents
              'currency': 'usd',
            });

            final clientSecret = response.data['clientSecret'];

            final paymentIntentResult = await StripePayment.confirmPaymentIntent(
              PaymentIntent(
                clientSecret: clientSecret,
                paymentMethodId: paymentMethod.id,
              ),
            );

            if (paymentIntentResult.status == 'succeeded') {
              _showDialog('Payment successful');
            } else {
              _showDialog('Payment failed: ${paymentIntentResult.status}');
            }
          } catch (error) {
            _showDialog('Payment error: $error');
          }




    }
  }
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter card number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter expiry date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(labelText: 'CVV'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter CVV';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cardHolderNameController,
                decoration: InputDecoration(labelText: 'Cardholder Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _processPayment,
                child: Text('Pay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

