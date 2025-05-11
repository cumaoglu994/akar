import 'dart:io';
import 'package:akar/screens/auth/login_screen.dart';
import 'package:akar/screens/home/home_screen.dart';
import 'package:akar/screens/home/main_screen.dart';
import 'package:akar/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/home_service.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({super.key});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCity;
  int? _selectedCurrencyId;
  List<File> _images = [];
  bool _isLoading = false;
  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  List<dynamic> _currencies = [];
  String? _selectedCountry;
  List<String> _countries = [];
  List<dynamic> _filteredCities = [];
  final HomeService _homeService = HomeService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCities();
    _loadCurrencies();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _homeService.getCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategory = categories[0]['name']?.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل الفئات: $e');
      }
    }
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _homeService.getCity();
      setState(() {
        _cities = cities;
        _countries = _cities.map((city) => city['country'].toString()).toSet().toList();
        if (_countries.isNotEmpty) {
          _selectedCountry = _countries[0];
          _filteredCities = _cities.where((city) => city['country'] == _selectedCountry).toList();
          if (_filteredCities.isNotEmpty) {
            _selectedCity = _filteredCities[0]['name']?.toString();
          } else {
            _selectedCity = null;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل المدن: $e');
      }
    }
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await _homeService.getCurrencies();
      setState(() {
        _currencies = currencies;
        if (currencies.isNotEmpty) {
          _selectedCurrencyId = currencies[0]['id'];
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل العملات: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    
    if (_images.length >= 10) {
      _showErrorSnackBar('يمكنك إضافة 10 صور كحد أقصى');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'إضافة صور',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.blue),
                  ),
                  title: const Text('اختيار من المعرض'),
                  onTap: () async {
                    Navigator.pop(context);
                    final List<XFile> pickedFiles = await picker.pickMultiImage();
                    if (pickedFiles.isNotEmpty) {
                      final remainingSlots = 10 - _images.length;
                      final filesToAdd = pickedFiles.take(remainingSlots).toList();
                      setState(() {
                        _images.addAll(filesToAdd.map((file) => File(file.path)));
                      });
                      if (pickedFiles.length > remainingSlots) {
                        _showErrorSnackBar('تم إضافة الحد الأقصى من الصور (10 صور)');
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  title: const Text('التقط صورة'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      if (_images.length < 10) {
                        setState(() {
                          _images.add(File(photo.path));
                        });
                      } else {
                        _showErrorSnackBar('يمكنك إضافة 10 صور كحد أقصى');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _uploadImage(File image) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
    final response = await Supabase.instance.client.storage
        .from('ads_images')
        .upload(fileName, image);
    
    return Supabase.instance.client.storage
        .from('ads_images')
        .getPublicUrl(fileName);
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      _showErrorSnackBar('لإضافة إعلان، يرجى تسجيل الدخول أولاً');
      Navigator.of(context).pushNamed('/login');
      return;
    }

    if (_images.isEmpty) {
      _showErrorSnackBar('الرجاء إضافة صورة واحدة على الأقل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images and get URLs
      final List<String> imageUrls = [];
      for (var image in _images) {
        imageUrls.add(await _uploadImage(image));
      }

      // Save ad to Supabase
      await Supabase.instance.client.from('ads').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': int.parse(_priceController.text),
        'currency_id': _selectedCurrencyId,
        'city': _selectedCity,
        'category': _selectedCategory,
        'images': imageUrls,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'waiting',
      });

      if (mounted) {
        final snackBar = SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'تم إضافة الإعلان بنجاح - في انتظار الموافقة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'حسناً',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        
        NavigationHelper.pushReplacement(
          context,
          const HomeScreen(),
        );
      }
    } catch (e, stack) {
      print('Hata: $e');
      print('Stack trace: $stack');
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('إضافة إعلان جديد',
        //     style: TextStyle(fontWeight: FontWeight.bold),
        //   ),
        //   elevation: 0,
        //   centerTitle: true,
        //   backgroundColor: Colors.transparent,
        //   foregroundColor: Theme.of(context).primaryColor,
        // ),
        body: user == null
            ? _buildLoginPrompt()
            : _buildAddAdForm(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'لإضافة إعلان، يرجى تسجيل الدخول أولاً',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'يمكنك تسجيل الدخول أو إنشاء حساب جديد للمتابعة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAdForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'معلومات الإعلان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: _getInputDecoration('عنوان الإعلان', Icons.title),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان الإعلان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _getInputDecoration('وصف الإعلان', Icons.description),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وصف الإعلان';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _getInputDecoration('السعر', Icons.monetization_on),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال السعر';
                        }
                        if (int.tryParse(value) == null) {
                          return 'الرجاء إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      value: _selectedCurrencyId,
                      decoration: _getInputDecoration('العملة', Icons.currency_exchange),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem<int>(
                          value: currency['id'],
                          child: Text('${currency['symbol']} - ${currency['name']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrencyId = value);
                        }
                      },
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.arrow_drop_down_circle),
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'الموقع والتصنيف',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: _getInputDecoration('الدولة', Icons.flag),
                items: _countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountry = value;
                      _filteredCities = _cities.where((city) => city['country'] == value).toList();
                      _selectedCity = _filteredCities.isNotEmpty ? _filteredCities[0]['name']?.toString() : null;
                    });
                  }
                },
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down_circle),
                style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: (() {
                  final cityNames = _filteredCities
                      .map((city) => city['name']?.toString())
                      .where((name) => name != null && name.isNotEmpty)
                      .toSet()
                      .toList();
                  return cityNames.contains(_selectedCity) ? _selectedCity : null;
                })(),
                decoration: _getInputDecoration('المدينة', Icons.location_city),
                items: _filteredCities
                    .map((city) => city['name']?.toString())
                    .where((name) => name != null && name.isNotEmpty)
                    .toSet()
                    .toList()
                    .map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCity = value);
                  }
                },
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down_circle),
                style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categories.any((cat) => cat['name']?.toString() == _selectedCategory)
                    ? _selectedCategory
                    : null,
                decoration: _getInputDecoration('الفئة', Icons.category),
                items: _categories.map((category) {
                  final name = category['name']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down_circle),
                style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'صور الإعلان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'أضف صور واضحة لإعلانك (بحد أقصى 10 صور)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImages,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة صور',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_images.length}/10 صور',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.file(
                                _images[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _images.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.publish),
                            SizedBox(width: 10),
                            Text(
                              'نشر الإعلان',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}