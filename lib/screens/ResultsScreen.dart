import 'package:flutter/material.dart';
import 'dart:typed_data';

class ResultsScreen extends StatelessWidget {
  final Uint8List capturedImage;

  ResultsScreen({required this.capturedImage});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> results = List.generate(10, (index) => {
      'image': 'https://via.placeholder.com/150',
      'title': 'MANGO KNITTED BLACK TOP-WOMEN',
      'price': '\$26',
      'store': 'Amazon',
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Best Results',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top container for captured image
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                width: 150, // Set fixed width
                height: 200, // Set fixed height
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    capturedImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Expanded widget for scrollable list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            result['image']!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result['title']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.store, size: 16, color: Colors.black54),
                                  SizedBox(width: 4),
                                  Text(
                                    result['store']!,
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                result['price']!,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
