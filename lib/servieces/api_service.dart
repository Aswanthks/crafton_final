import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../modules/auth/login_screen.dart';
import '../modules/student/home/student_root_screen.dart';
import '../modules/user/checkout/order_placed_screen.dart';
import 'db_services.dart';

class ApiService {
  static const baseUrl = 'https://vadakara-mca-craft-backend.onrender.com';

  Future<void> registerUser({
    required String name,
    required String email,
    required String mobile,
    required String address,
    required String password,
    required BuildContext context,
  }) async {
    String url = '$baseUrl/api/register/user';

    // Define the request body
    Map<String, String> body = {
      'name': name,
      'email': email,
      'mobile': mobile,
      'address': address,
      'password': password,
    };

    // Send the POST request
    try {
      final response = await http.post(Uri.parse(url), body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User registered successfully'),
          ),
        );

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Login_page(),
            ),
            (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to register user: ${jsonDecode(response.body)['Message']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering user: $e'),
        ),
      );
    }
  }

  //register student
  Future<void> registerStudent(
      {required String name,
      required String email,
      required String mobile,
      required String address,
      required String stream,
      required String academicYear,
      required String courseName,
      required String password,
      required BuildContext context}) async {
    final url = Uri.parse('$baseUrl/api/register/student');
    final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    final body = {
      "name": name,
      "email": email,
      "mobile": mobile,
      "address": address,
      "stream": stream,
      "academic_year": academicYear,
      "course_name": courseName,
      "password": password
    };

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Login_page(),
            ),
            (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: ${response.statusCode}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during registration: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<int?> login(
      {required BuildContext context,
      required String email,
      required String password}) async {
    final url = Uri.parse('$baseUrl/api/login');

    try {
      final response = await http.post(
        url,
        body: {
          'email': email.trim(),
          'password': password.trim(),
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        await DbService.setLoginId(data['loginId']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful'),
            duration: Duration(seconds: 2),
          ),
        );

        return data['userRole'];

        // Login successful, handle the response here
      } else {
        // Login failed, handle the response here
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(jsonDecode(response.body)['Message']),
          duration: Duration(seconds: 2),
        ));

        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        duration: Duration(seconds: 2),
      ));
    }
  }

//add product
  Future<void> addProduct({
    required String productName,
    required String price,
    required String description,
    required String image,
    required String quantity,
    required BuildContext context,
  }) async {
    String url = '$baseUrl/api/student/add-product';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['product_name'] = productName;
    request.fields['price'] = price;
    request.fields['description'] = description;
    request.fields['quantity'] = quantity;
    request.fields['login_id'] = DbService.getLoginId()!;

    var imageFile = await http.MultipartFile.fromPath('image', image);

    request.files.add(imageFile);

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product added successfully')),
          );

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRootScreen(),
              ),
              (route) => false);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to add product. Status code: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> deleteProduct(BuildContext context, String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/student/delete-product/$id'),
      );

      if (response.statusCode == 200) {
        // Product deleted successfully
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } else {
        // Failed to delete product
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete product')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  Future<void> updateProduct(
    BuildContext context, {
    required String productId,
    required String productName,
    required double price,
    required String description,
    required int quantity,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/student/update-product/$productId'),
      );
      request.fields['product_name'] = productName;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;
      request.fields['quantity'] = quantity.toString();
      if (imagePath != null) {
        var image = await http.MultipartFile.fromPath(
          'image',
          imagePath,
        );
        request.files.add(image);
      }

      var streamedResponse = await request.send();

      print(streamedResponse.stream);
      if (streamedResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    }
  }

  Future<void> addHighlights(BuildContext context, String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/student/add-highlights/$productId'),
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        // Highlights added successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Highlights added successfully')),
        );
      } else {
        // Failed to add highlights
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add highlights')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding highlights: $e')),
      );
    }
  }

  //update profile

  Future<void> updateProfile(
      {required BuildContext context,
      required String id,
      required String name,
      required String mobile,
      required String academicYear,
      required String courseName,
      required String stream,
      required String address}) async {
    try {
      final Uri url = Uri.parse('$baseUrl/api/student/update-profile');
      final response = await http.post(url, body: {
        'name': name,
        'mobile': mobile,
        'academic_year': academicYear,
        'course_name': courseName,
        'id': DbService.getLoginId()
      });

      print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile update faild'),
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
        ),
      );
    }
  }

  Future<void> addToCart({
    required String loginId,
    required String productId,
    required double price,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/api/user/add-to-cart/$loginId/$productId'),
        body: {'price': price.toString()},
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to cart successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to cart Faild')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Somthing went wrong')),
      );
    }
  }

  //update quantity
  Future<void> updateCartQuantity(
      {required BuildContext context,
      required String id,
      required int quantity}) async {
    try {
      final Uri url =
          Uri.parse('${ApiService.baseUrl}/api/user/update-cart-quantity/$id');
      final response = await http.post(
        url,
        body: {
          'quantity': quantity.toString(),
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity updated successfully'),
          ),
        );
      } else {
        throw Exception('Failed to update quantity');
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
        ),
      );
    }
  }

  Future<void> deleteCartItem(String id, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/user/delete-cart/$id'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  Future<void> orderProduct(
      {required String loginId, required BuildContext context}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/order-product/$loginId'),
      );

      print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ordered successfully')),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderPlaced(),
            ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to order product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to order product: $e')),
      );
    }
  }

  Future<void> updateUserProfile(
      {required String loginId,
      required String name,
      required String mobile,
      required String address,
      required BuildContext context}) async {
    final url = Uri.parse(
        '$baseUrl/api/user/update-user-profile/${DbService.getLoginId()}');

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'name': name,
      'mobile': mobile,
      'address': address,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Successfull')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Faild')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Faild')));
    }
  }

  Future<void> confirmOrder(
      {required BuildContext context, required String orderId}) async {
    final url = Uri.parse('$baseUrl/api/student/confirm-order/$orderId');

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order confirmed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to confirm order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> addComplaint({
    required String loginId,
    required String productId,
    required String complaint,
    required BuildContext context,
    required String title,
  }) async {
    final url =
        'https://vadakara-mca-craft-backend.onrender.com/api/user/add-complaint';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'login_id': loginId,
          'product_id': productId,
          'complaint': complaint,
          'title': title
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Show a Snackbar with the title
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint added'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add complaint'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> addFeedback(
      {required String loginId,
      required String productId,
      required String feedback,
      required BuildContext context}) async {
    final url =
        'https://vadakara-mca-craft-backend.onrender.com/api/user/add-feedback';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'login_id': loginId,
          'product_id': productId,
          'feedback': feedback,
          'reply': '....',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        print(responseData);

        // Show a Snackbar with the message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback added'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add feedback'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

//all product
}
