import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MiStockApp());
}

class MiStockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: LoginPage(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, 'mistock.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        tipoDocumento TEXT NOT NULL,
        numeroDocumento TEXT NOT NULL,
        telefono TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fotoPerfil TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        telefono TEXT NOT NULL,
        monto REAL NOT NULL,
        fechaPago TEXT,
        estado TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        unidadMedida TEXT NOT NULL,
        stock INTEGER NOT NULL,
        precioUnitario REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        montoTotal REAL NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (productoId) REFERENCES productos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pagos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clienteId INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (clienteId) REFERENCES clientes (id)
      )
    ''');
  }

  Future<int> registrarUsuario(Map<String, dynamic> usuario) async {
    Database db = await database;
    return await db.insert('usuarios', usuario);
  }

  Future<Map<String, dynamic>?> loginUsuario(
      String correo, String contrasena) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'usuarios',
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [correo, contrasena],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> actualizarUsuario(Map<String, dynamic> usuario) async {
    Database db = await database;
    return await db.update(
      'usuarios',
      usuario,
      where: 'id = ?',
      whereArgs: [usuario['id']],
    );
  }

  Future<int> agregarCliente(Map<String, dynamic> cliente) async {
    Database db = await database;
    return await db.insert('clientes', cliente);
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    Database db = await database;
    return await db.query('clientes');
  }

  Future<int> eliminarCliente(int id) async {
    Database db = await database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> agregarProducto(Map<String, dynamic> producto) async {
    Database db = await database;
    return await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    Database db = await database;
    return await db.query('productos');
  }

  Future<int> eliminarProducto(int id) async {
    Database db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos CRUD para ventas
  Future<int> agregarVenta(Map<String, dynamic> venta) async {
    Database db = await database;
    return await db.insert('ventas', venta);
  }

  Future<List<Map<String, dynamic>>> obtenerVentas() async {
    Database db = await database;
    return await db.query('ventas');
  }

  Future<int> agregarPago(Map<String, dynamic> pago) async {
    Database db = await database;
    return await db.insert('pagos', pago);
  }

  Future<List<Map<String, dynamic>>> obtenerPagos() async {
    Database db = await database;
    return await db.query('pagos');
  }

  Future<int> actualizarPago(Map<String, dynamic> pago) async {
    Database db = await database;
    return await db.update(
      'pagos',
      pago,
      where: 'id = ?',
      whereArgs: [pago['id']],
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store, size: 50, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      'MiStock',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Inicia sesión con tu cuenta',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: correoController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Por favor, ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: contrasenaController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      var usuario = await dbHelper.loginUsuario(
                        correoController.text,
                        contrasenaController.text,
                      );
                      if (usuario != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(usuario: usuario),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Credenciales incorrectas'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Iniciar sesión'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage1()),
                    );
                  },
                  child: Text('Regístrate ahora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage1 extends StatefulWidget {
  @override
  _RegisterPage1State createState() => _RegisterPage1State();
}

class _RegisterPage1State extends State<RegisterPage1> {
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController numeroDocumentoController =
      TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final List<String> tiposDocumento = ['DNI', 'Pasaporte'];
  String tipoDocumentoSeleccionado = 'DNI';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos personales'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.store, size: 50, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'MiStock',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nombresController,
                decoration: InputDecoration(
                  labelText: 'Nombres',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese sus nombres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: apellidosController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese sus apellidos';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: tipoDocumentoSeleccionado,
                items: tiposDocumento.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    tipoDocumentoSeleccionado = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Tipo de documento',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: numeroDocumentoController,
                decoration: InputDecoration(
                  labelText: 'Número de documento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su número de documento';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !RegExp(r'^\d{9}$').hasMatch(value)) {
                    return 'Por favor, ingrese un número de celular válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterPage2(
                          nombres: nombresController.text,
                          apellidos: apellidosController.text,
                          tipoDocumento: tipoDocumentoSeleccionado,
                          numeroDocumento: numeroDocumentoController.text,
                          telefono: telefonoController.text,
                        ),
                      ),
                    );
                  }
                },
                child: Text('Siguiente'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage2 extends StatefulWidget {
  final String nombres;
  final String apellidos;
  final String tipoDocumento;
  final String numeroDocumento;
  final String telefono;

  RegisterPage2({
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
  });

  @override
  _RegisterPage2State createState() => _RegisterPage2State();
}

class _RegisterPage2State extends State<RegisterPage2> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos de la cuenta'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.store, size: 50, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'MiStock',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: correoController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.contains('@')) {
                    return 'Por favor, ingrese un correo válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: contrasenaController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Map<String, dynamic> usuario = {
                      'nombres': widget.nombres,
                      'apellidos': widget.apellidos,
                      'tipoDocumento': widget.tipoDocumento,
                      'numeroDocumento': widget.numeroDocumento,
                      'telefono': widget.telefono,
                      'correo': correoController.text,
                      'contrasena': contrasenaController.text,
                      'fotoPerfil': null,
                    };
                    await dbHelper.registrarUsuario(usuario);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: Text('Registrarse'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  MainPage({required this.usuario});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late Map<String, dynamic> usuario;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
    _pages = [
      HomePage(usuario: usuario),
      PagosPage(usuario: usuario),
      ClientesPage(usuario: usuario),
      InventarioPage(usuario: usuario),
      PerfilPage(usuario: usuario),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MiStock'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'assets/logo_mistock.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'General',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  HomePage({required this.usuario});

  @override
  _HomePageState createState() => _HomePageState();
}

class Bodega {
  String nombre;
  String direccion;
  Bodega(this.nombre, this.direccion);
}

class _HomePageState extends State<HomePage> {
  List<Bodega> bodegas = [
    Bodega('Bodega Central', 'Av. Principal 123'),
    Bodega('Bodega Secundaria', 'Calle Secundaria 456'),
  ];
  Bodega? bodegaSeleccionada;
  List<Map<String, dynamic>> ventas = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (bodegas.isNotEmpty) {
      bodegaSeleccionada = bodegas[0];
    }
    cargarVentas();
  }

  void cargarVentas() async {
    List<Map<String, dynamic>> data = await dbHelper.obtenerVentas();
    setState(() {
      ventas = data;
    });
  }

  void agregarVenta(Map<String, dynamic> venta) async {
    await dbHelper.agregarVenta(venta);
    cargarVentas();
  }

  @override
  Widget build(BuildContext context) {
    String usuarioNombre =
        '${widget.usuario['nombres']} ${widget.usuario['apellidos']}';
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'General',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<Bodega>(
                  value: bodegaSeleccionada,
                  items: bodegas.map((Bodega bodega) {
                    return DropdownMenuItem<Bodega>(
                      value: bodega,
                      child: Row(
                        children: [
                          Icon(Icons.store),
                          SizedBox(width: 10),
                          Text(bodega.nombre),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      bodegaSeleccionada = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Bodega',
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 10),
                    Text(bodegaSeleccionada != null
                        ? bodegaSeleccionada!.direccion
                        : 'Sin dirección'),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text(usuarioNombre),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Ventas'),
                    trailing: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AgregarVentaPopup(
                            agregarVenta: agregarVenta,
                          ),
                        );
                      },
                      child: Text('Agregar'),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: ventas.length,
                      itemBuilder: (context, index) {
                        final venta = ventas[index];
                        return ListTile(
                          title: Text('Producto ID: ${venta['productoId']}'),
                          subtitle: Text(venta['fecha']),
                          trailing: Text('\$${venta['montoTotal']}'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => VerVentaPopup(venta: venta),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgregarVentaPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) agregarVenta;
  AgregarVentaPopup({required this.agregarVenta});

  @override
  _AgregarVentaPopupState createState() => _AgregarVentaPopupState();
}

class _AgregarVentaPopupState extends State<AgregarVentaPopup> {
  int? productoSeleccionado;
  List<Map<String, dynamic>> productos = [];
  TextEditingController cantidadController = TextEditingController();
  TextEditingController montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  void cargarProductos() async {
    List<Map<String, dynamic>> data = await dbHelper.obtenerProductos();
    setState(() {
      productos = data;
      if (productos.isNotEmpty) {
        productoSeleccionado = productos[0]['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar Venta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              productos.isNotEmpty
                  ? DropdownButtonFormField<int>(
                      value: productoSeleccionado,
                      items: productos.map((producto) {
                        return DropdownMenuItem<int>(
                          value: producto['id'],
                          child: Text(producto['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          productoSeleccionado = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Producto',
                      ),
                    )
                  : Text('No hay productos disponibles'),
              TextFormField(
                controller: cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) <= 0) {
                    return 'Ingrese una cantidad válida';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: montoController,
                decoration: InputDecoration(
                  labelText: 'Monto total',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Map<String, dynamic> venta = {
                'productoId': productoSeleccionado,
                'cantidad': int.parse(cantidadController.text),
                'montoTotal': double.parse(montoController.text),
                'fecha': DateTime.now().toString(),
              };
              await dbHelper.agregarVenta(venta);
              widget.agregarVenta(venta);
              Navigator.pop(context);
            }
          },
          child: Text('Registrar'),
        ),
      ],
    );
  }
}

class VerVentaPopup extends StatelessWidget {
  final Map<String, dynamic> venta;
  VerVentaPopup({required this.venta});

  @override
  Widget build(BuildContext context) {
    double precioUnitario = venta['montoTotal'] / venta['cantidad'];

    return AlertDialog(
      title: Text('Detalles de venta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Producto ID: ${venta['productoId']}'),
          Text('Precio unitario: \$${precioUnitario.toStringAsFixed(2)}'),
          Text('Cantidad total: ${venta['cantidad']}'),
          Text('Monto total: \$${venta['montoTotal']}'),
          Text('Fecha y hora registrada: ${venta['fecha']}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}

class PerfilPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  PerfilPage({required this.usuario});

  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool editar = false;
  late TextEditingController nombresController;
  late TextEditingController apellidosController;
  late TextEditingController correoController;
  File? imagenPerfil;
  final picker = ImagePicker();
  final dbHelper = DatabaseHelper();
  late Map<String, dynamic> usuarioMutable;

  @override
  void initState() {
    super.initState();
    nombresController =
        TextEditingController(text: widget.usuario['nombres']);
    apellidosController =
        TextEditingController(text: widget.usuario['apellidos']);
    correoController = TextEditingController(text: widget.usuario['correo']);
    if (widget.usuario['fotoPerfil'] != null) {
      imagenPerfil = File(widget.usuario['fotoPerfil']);
    }
    usuarioMutable = Map<String, dynamic>.from(widget.usuario);
  }

  Future<void> _cambiarFotoPerfil() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        imagenPerfil = File(pickedFile.path);
      });
    }
  }

  void _guardarCambios() async {
    usuarioMutable['nombres'] = nombresController.text;
    usuarioMutable['apellidos'] = apellidosController.text;
    usuarioMutable['correo'] = correoController.text;
    if (imagenPerfil != null) {
      usuarioMutable['fotoPerfil'] = imagenPerfil!.path;
    }
    await dbHelper.actualizarUsuario(usuarioMutable);
    setState(() {
      editar = false;
    });
  }

  void _cancelarEdicion() {
    setState(() {
      editar = false;
      nombresController.text = widget.usuario['nombres'];
      apellidosController.text = widget.usuario['apellidos'];
      correoController.text = widget.usuario['correo'];
      if (widget.usuario['fotoPerfil'] != null) {
        imagenPerfil = File(widget.usuario['fotoPerfil']);
      } else {
        imagenPerfil = null;
      }
    });
  }

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: editar ? _cambiarFotoPerfil : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: imagenPerfil != null
                    ? FileImage(imagenPerfil!)
                    : AssetImage('assets/default_profile.png')
                        as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            editar
                ? TextField(
                    controller: nombresController,
                    decoration: InputDecoration(labelText: 'Nombres'),
                  )
                : Text('Nombres: ${nombresController.text}'),
            editar
                ? TextField(
                    controller: apellidosController,
                    decoration: InputDecoration(labelText: 'Apellidos'),
                  )
                : Text('Apellidos: ${apellidosController.text}'),
            editar
                ? TextField(
                    controller: correoController,
                    decoration: InputDecoration(labelText: 'Correo'),
                  )
                : Text('Correo: ${correoController.text}'),
            SizedBox(height: 20),
            editar
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: _guardarCambios,
                        child: Text('Guardar'),
                      ),
                      TextButton(
                        onPressed: _cancelarEdicion,
                        child: Text('Cancelar'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        editar = true;
                      });
                    },
                    child: Text('Editar datos'),
                  ),
          ],
        ),
      ),
    );
  }
}

class ClientesPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  ClientesPage({required this.usuario});

  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List<Map<String, dynamic>> clientes = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  void cargarClientes() async {
    List<Map<String, dynamic>> data = await dbHelper.obtenerClientes();
    setState(() {
      clientes = data;
    });
  }

  void agregarCliente(Map<String, dynamic> cliente) async {
    await dbHelper.agregarCliente(cliente);
    cargarClientes();
  }

  void eliminarCliente(int id) async {
    await dbHelper.eliminarCliente(id);
    cargarClientes();
  }

  @override
  Widget build(BuildContext context) {
    int totalClientes = clientes.length;
    int clientesRecurrentes =
        clientes.where((c) => c['estado'] == 'No Deudor').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Divider(),
                  Text('Número total de clientes'),
                  Text('$totalClientes'),
                  Text('Clientes nuevos este mes: 0%'),
                  Divider(),
                  Text('Clientes recurrentes'),
                  Text('$clientesRecurrentes'),
                  Text(
                      'Porcentaje: ${totalClientes > 0 ? (clientesRecurrentes / totalClientes * 100).toStringAsFixed(2) : 0}%'),
                  Divider(),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Clientes'),
                      trailing: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => RegistrarClientePopup(
                              agregarCliente: agregarCliente,
                            ),
                          );
                        },
                        child: Text('Agregar'),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: clientes.length,
                        itemBuilder: (context, index) {
                          final cliente = clientes[index];
                          return ListTile(
                            title: Text(
                                '${cliente['nombres']} ${cliente['apellidos']}'),
                            subtitle: Text(cliente['estado']),
                            trailing: Text('\$${cliente['monto']}'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => VistaClientePopup(
                                  cliente: cliente,
                                  eliminarCliente: eliminarCliente,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrarClientePopup extends StatefulWidget {
  final Function(Map<String, dynamic>) agregarCliente;
  RegistrarClientePopup({required this.agregarCliente});

  @override
  _RegistrarClientePopupState createState() => _RegistrarClientePopupState();
}

class _RegistrarClientePopupState extends State<RegistrarClientePopup> {
  bool registrar = true;
  TextEditingController nombresController = TextEditingController();
  TextEditingController apellidosController = TextEditingController();
  TextEditingController celularController = TextEditingController();
  TextEditingController montoController = TextEditingController();
  TextEditingController fechaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? fechaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar nuevo cliente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Acción a realizar'),
                value: registrar,
                onChanged: (value) {
                  setState(() {
                    registrar = value;
                  });
                },
                secondary: Text(registrar ? 'Registrar' : 'Actualizar'),
              ),
              TextFormField(
                controller: nombresController,
                decoration: InputDecoration(labelText: 'Nombres'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese los nombres';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: apellidosController,
                decoration: InputDecoration(labelText: 'Apellidos'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese los apellidos';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: celularController,
                decoration: InputDecoration(labelText: 'Número de celular'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !RegExp(r'^\d{9}$').hasMatch(value)) {
                    return 'Ingrese un número de celular válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: montoController,
                decoration: InputDecoration(labelText: 'Monto a pagar'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) < 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: fechaController,
                decoration: InputDecoration(labelText: 'Fecha de pago'),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(new FocusNode());
                  fechaSeleccionada = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (fechaSeleccionada != null) {
                    fechaController.text =
                        fechaSeleccionada!.toLocal().toString().split(' ')[0];
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una fecha de pago';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Map<String, dynamic> cliente = {
                'nombres': nombresController.text,
                'apellidos': apellidosController.text,
                'telefono': celularController.text,
                'monto': double.parse(montoController.text),
                'fechaPago': fechaController.text,
                'estado': double.parse(montoController.text) > 0
                    ? 'Deudor'
                    : 'No Deudor',
              };
              widget.agregarCliente(cliente);
              Navigator.pop(context);
            }
          },
          child: Text(registrar ? 'Registrar' : 'Actualizar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}

class VistaClientePopup extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final Function(int) eliminarCliente;

  VistaClientePopup({required this.cliente, required this.eliminarCliente});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Vista del cliente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nombre: ${cliente['nombres']} ${cliente['apellidos']}'),
          Text('Número de celular: ${cliente['telefono']}'),
          Text('Estado: ${cliente['estado']}'),
          Text('Monto: \$${cliente['monto']}'),
          Text('Fecha de pago: ${cliente['fechaPago']}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Aceptar'),
        ),
        TextButton(
          onPressed: () {
            eliminarCliente(cliente['id']);
            Navigator.pop(context);
          },
          child: Text('Eliminar'),
        ),
      ],
    );
  }
}

class InventarioPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  InventarioPage({required this.usuario});

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  List<Map<String, dynamic>> productos = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  void cargarProductos() async {
    List<Map<String, dynamic>> data = await dbHelper.obtenerProductos();
    setState(() {
      productos = data;
    });
  }

  void agregarProducto(Map<String, dynamic> producto) async {
    await dbHelper.agregarProducto(producto);
    cargarProductos();
  }

  void eliminarProducto(int id) async {
    await dbHelper.eliminarProducto(id);
    cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    int ventasMes = 1000;
    String mesActual = '${DateTime.now().month}/${DateTime.now().year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 10),
                      Text('Ventas del mes'),
                    ],
                  ),
                  Text('Monto total: \$${ventasMes}'),
                  Text('Fecha: $mesActual'),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events),
                      SizedBox(width: 10),
                      Text('Mayores ventas'),
                    ],
                  ),
                  ...productos.map((producto) {
                    return Row(
                      children: [
                        Text(producto['nombre']),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 0.5,
                          ),
                        ),
                        Text('50%'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Productos'),
                      trailing: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => RegistrarProductoPopup(
                              agregarProducto: agregarProducto,
                            ),
                          );
                        },
                        child: Text('Agregar'),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          return ListTile(
                            title: Text(producto['nombre']),
                            subtitle: Text(producto['stock'] > 0
                                ? 'Disponible'
                                : 'Agotado'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => VistaProductoPopup(
                                  producto: producto,
                                  eliminarProducto: eliminarProducto,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrarProductoPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) agregarProducto;
  RegistrarProductoPopup({required this.agregarProducto});

  @override
  _RegistrarProductoPopupState createState() => _RegistrarProductoPopupState();
}

class _RegistrarProductoPopupState extends State<RegistrarProductoPopup> {
  bool registrar = true;
  TextEditingController nombreController = TextEditingController();
  TextEditingController unidadController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  TextEditingController precioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Acción a realizar'),
                value: registrar,
                onChanged: (value) {
                  setState(() {
                    registrar = value;
                  });
                },
                secondary: Text(registrar ? 'Registrar' : 'Actualizar'),
              ),
              TextFormField(
                controller: nombreController,
                decoration: InputDecoration(labelText: 'Nombre de producto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del producto';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: unidadController,
                decoration: InputDecoration(labelText: 'Unidad de medida'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la unidad de medida';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: stockController,
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) < 0) {
                    return 'Ingrese un stock válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: precioController,
                decoration: InputDecoration(labelText: 'Precio unitario'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Map<String, dynamic> producto = {
                'nombre': nombreController.text,
                'unidadMedida': unidadController.text,
                'stock': int.parse(stockController.text),
                'precioUnitario': double.parse(precioController.text),
                'fechaRegistro': DateTime.now().toString(),
              };
              widget.agregarProducto(producto);
              Navigator.pop(context);
            }
          },
          child: Text('Registrar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}

class VistaProductoPopup extends StatelessWidget {
  final Map<String, dynamic> producto;
  final Function(int) eliminarProducto;

  VistaProductoPopup({required this.producto, required this.eliminarProducto});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Vista de Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nombre del producto: ${producto['nombre']}'),
          Text('Precio unitario: \$${producto['precioUnitario']}'),
          Text('Stock: ${producto['stock']}'),
          Text('Unidad de medida: ${producto['unidadMedida']}'),
          Text('Fecha de registro: ${producto['fechaRegistro']}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Aceptar'),
        ),
        TextButton(
          onPressed: () {
            eliminarProducto(producto['id']);
            Navigator.pop(context);
          },
          child: Text('Eliminar'),
        ),
      ],
    );
  }
}

class PagosPage extends StatefulWidget {
  final Map<String, dynamic> usuario;

  PagosPage({required this.usuario});

  @override
  _PagosPageState createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
  bool mostrarCanceladas = true;
  List<Map<String, dynamic>> pagosCancelados = [];
  List<Map<String, dynamic>> pagosPendientes = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    cargarPagos();
  }

  void cargarPagos() async {
    List<Map<String, dynamic>> data = await dbHelper.obtenerPagos();
    setState(() {
      pagosCancelados = data.where((p) => p['estado'] == 'Cancelado').toList();
      pagosPendientes = data.where((p) => p['estado'] == 'Pendiente').toList();
    });
  }

  void actualizarPago(Map<String, dynamic> pago) async {
    await dbHelper.actualizarPago(pago);
    cargarPagos();
  }

  @override
  Widget build(BuildContext context) {
    double montoTotalCanceladas = pagosCancelados.fold<double>(
        0,
        (sum, item) => sum +
            (item['monto'] != null ? double.parse(item['monto'].toString()) : 0));
    double montoTotalPendientes = pagosPendientes.fold<double>(
        0,
        (sum, item) => sum +
            (item['monto'] != null ? double.parse(item['monto'].toString()) : 0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagos'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 10),
                      Text('Canceladas'),
                    ],
                  ),
                  Text(
                      'Monto total: \$${montoTotalCanceladas.toStringAsFixed(2)}'),
                  Text('Fecha: ${DateTime.now().toLocal()}'),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_empty),
                      SizedBox(width: 10),
                      Text('Pendientes'),
                    ],
                  ),
                  Text(
                      'Monto total: \$${montoTotalPendientes.toStringAsFixed(2)}'),
                  Text('Fecha: ${DateTime.now().toLocal()}'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      mostrarCanceladas = true;
                    });
                  },
                  child: Text('Canceladas'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      mostrarCanceladas = false;
                    });
                  },
                  child: Text('Pendientes'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: mostrarCanceladas
                    ? pagosCancelados.length
                    : pagosPendientes.length,
                itemBuilder: (context, index) {
                  final pago = mostrarCanceladas
                      ? pagosCancelados[index]
                      : pagosPendientes[index];
                  return ListTile(
                    title: Text('Cliente ID: ${pago['clienteId']}'),
                    trailing: IconButton(
                      icon: Icon(mostrarCanceladas
                          ? Icons.visibility
                          : Icons.credit_card),
                      onPressed: () {
                        if (mostrarCanceladas) {
                          showDialog(
                            context: context,
                            builder: (context) => VistaPagoPopup(pago: pago),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => PagarDeudaPopup(
                              pago: pago,
                              actualizarPago: actualizarPago,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaPagoPopup extends StatelessWidget {
  final Map<String, dynamic> pago;
  VistaPagoPopup({required this.pago});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Vista de pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Cliente ID: ${pago['clienteId']}'),
          Text('Monto cancelado: \$${pago['monto']}'),
          Text('Fecha de deuda: ${pago['fecha']}'),
          Text('Estado: ${pago['estado']}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}

class PagarDeudaPopup extends StatefulWidget {
  final Map<String, dynamic> pago;
  final Function(Map<String, dynamic>) actualizarPago;

  PagarDeudaPopup({required this.pago, required this.actualizarPago});

  @override
  _PagarDeudaPopupState createState() => _PagarDeudaPopupState();
}

class _PagarDeudaPopupState extends State<PagarDeudaPopup> {
  TextEditingController montoController = TextEditingController();
  double deudaPendiente = 0;

  @override
  void initState() {
    super.initState();
    montoController.text = widget.pago['monto'].toString();
    deudaPendiente = widget.pago['monto'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 10),
              Text('Cliente ID: ${widget.pago['clienteId']}'),
            ],
          ),
          Text('Deuda: \$${widget.pago['monto']}'),
          TextField(
            controller: montoController,
            decoration: InputDecoration(labelText: 'Monto a cancelar'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                double pagoRealizado = double.tryParse(value) ?? 0;
                deudaPendiente = widget.pago['monto'] - pagoRealizado;
              });
            },
          ),
          Text('Deuda pendiente: \$${deudaPendiente.toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.pago['estado'] = 'Cancelado';
            widget.actualizarPago(widget.pago);
            Navigator.pop(context);
          },
          child: Text('Pagar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}
