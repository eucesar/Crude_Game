// Importa utilitários para trabalhar com JSON
import 'dart:convert';

// Flutter UI e cliente HTTP
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Centralização da URL da API
class ApiConfig {
  static const String baseUrl = "https://videogames-api-bbf46be3e1a8.herokuapp.com";
  // Endpoint: lista/cria jogos
  static String games() => "$baseUrl/games";
  // Endpoint: obtém/atualiza/deleta por id
  static String gameById(int id) => "$baseUrl/games/$id";
  // Endpoint: lista URLs de banners
  static String banners() => "$baseUrl/banners";
}

/// Classe que representa um jogo do backend
class Game {
  final int id;
  final String name;
  final String genre;
  final String platform;
  final String imageUrl;

  Game({
    required this.id,
    required this.name,
    required this.genre,
    required this.platform,
    required this.imageUrl,
  });

  /// Transforma o Map<String,dynamic> (JSON) vindo da API em uma instância Game
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['title'] ?? json['name'] ?? json['titulo'], // Tenta 'title' primeiro
      genre: json['genre'] ?? json['genero'] ?? 'N/A', // Campo opcional
      platform: json['platform'] ?? json['plataforma'], // Tenta 'platform' primeiro
      imageUrl: json['imageUrl'] ?? json['imagemUrl'] ?? '', // Campo opcional para imagem
    );
  }
}

/// HomePage é um StatefulWidget porque precisa armazenar e atualizar a lista de jogos
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Estado local com a lista de jogos renderizada na tela
  List<Game> games = [];
  // Estado local com a lista de banners para o slider
  List<String> banners = [];

  @override
  void initState() {
    super.initState();
    fetchGames();
    fetchBanners();
  }

  /// Carrega a lista de jogos da API
  Future<void> fetchGames() async {
    // Faz GET na API para obter a listagem de jogos
    final response = await http.get(Uri.parse(ApiConfig.games()));
    if (response.statusCode == 200) {
      // Decodifica JSON em lista dinâmica
      final List<dynamic> data = json.decode(response.body);
      // Converte cada item em Game e atualiza o estado (re-render)
      setState(() {
        games = data.map((e) => Game.fromJson(e)).toList();
      });
    }
  }

  /// Carrega a lista de banners da API
  Future<void> fetchBanners() async {
    // Faz GET na API para obter a listagem de banners
    final response = await http.get(Uri.parse(ApiConfig.banners()));
    if (response.statusCode == 200) {
      // Decodifica JSON em lista dinâmica
      final List<dynamic> data = json.decode(response.body);
      // Converte cada item em String e atualiza o estado (re-render)
      setState(() {
        banners = data.map((e) => e.toString()).toList();
      });
    }
  }

  /// Abre o formulário e, ao retornar, recarrega a listagem
  void goToForm({Game? game}) async {
    print('=== NAVEGANDO PARA FORMULÁRIO ===');
    print('Game: ${game?.name ?? "Novo jogo"}');
    print('Game ID: ${game?.id ?? "null"}');
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameFormPage(game: game)),
    );
    
    print('=== RETORNOU DO FORMULÁRIO ===');
    print('Recarregando lista de jogos...');
    fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jogos")),
      body: Column(
        children: [
          // Slider de banners no topo
          if (banners.isNotEmpty)
            Container(
              height: 200,
              child: PageView.builder(
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        banners[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 50),
                                  Text("Banner não encontrado"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          // Lista de jogos
          Expanded(
            child: ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: game.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              game.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 30),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.videogame_asset, size: 30),
                          ),
                    title: Text(game.name),
                    subtitle: Text("${game.genre} - ${game.platform}"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => goToForm(game: game),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => goToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Tela de formulário para criação/edição de Game
class GameFormPage extends StatefulWidget {
  final Game? game;

  const GameFormPage({super.key, this.game});

  @override
  State<GameFormPage> createState() => _GameFormPageState();
}

class _GameFormPageState extends State<GameFormPage> {
  // Chave para validar e manipular o formulário
  final _formKey = GlobalKey<FormState>();
  // Controllers dos campos (lê/escreve programaticamente)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController platformController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill: se for edição, preenche os campos com os valores do jogo
    if (widget.game != null) {
      nameController.text = widget.game!.name;
      genreController.text = widget.game!.genre;
      platformController.text = widget.game!.platform;
      imageUrlController.text = widget.game!.imageUrl;
    }
  }

  /// Salva jogo: cria (POST) ou atualiza (PUT) conforme presença de id
  Future<void> saveGame() async {
    print('=== INICIANDO SALVAMENTO ===');
    print('Form válido: ${_formKey.currentState?.validate()}');
    
    if (_formKey.currentState!.validate()) {
      // Monta o payload a partir dos campos (usando campos que a API espera)
      final Map<String, dynamic> data = {
        "title": nameController.text,
        "platform": platformController.text,
        "imageUrl": imageUrlController.text,
      };

      print('Dados a serem enviados: $data');
      print('URL da API: ${ApiConfig.games()}');

      try {
        http.Response response;
        if (widget.game == null) {
          // Criação (POST)
          print('Fazendo POST para criar jogo...');
          response = await http.post(
            Uri.parse(ApiConfig.games()),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          );
        } else {
          // Edição (PUT) usando o id
          print('Fazendo PUT para editar jogo ID: ${widget.game!.id}');
          response = await http.put(
            Uri.parse(ApiConfig.gameById(widget.game!.id)),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          );
        }

        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // Se sucesso (2xx), fecha retornando para a lista
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('✅ Sucesso! Fechando tela...');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jogo salvo com sucesso!')),
            );
            Navigator.pop(context);
          }
        } else {
          // Mostra o erro específico da API
          String errorMessage = 'Falha ao salvar';
          try {
            final errorData = json.decode(response.body);
            if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            }
          } catch (e) {
            errorMessage = 'Erro ${response.statusCode}: ${response.body}';
          }
          
          print('❌ Erro: $errorMessage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      } catch (e) {
        print('❌ Exceção: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de conexão: $e')),
          );
        }
      }
    } else {
      // Form inválido: dá feedback ao usuário
      print('❌ Formulário inválido');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
    }
  }

  /// Deleta jogo via DELETE /games/{id}
  Future<void> deleteGame() async {
    if (widget.game == null) return;
    
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.gameById(widget.game!.id)),
      );
      
      // Se deletar com sucesso, fecha a tela
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Jogo excluído com sucesso!")),
          );
          Navigator.pop(context);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir jogo: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );
    }
  }

  // Diálogo de confirmação (retorna true/false)
  Future<bool> showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmação"),
        content: const Text("Deseja realmente excluir este jogo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.game != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Jogo" : "Novo Jogo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nome do jogo (obrigatório)
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nome do Jogo"),
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha o nome' : null,
              ),
              // Gênero (opcional)
              TextFormField(
                controller: genreController,
                decoration: const InputDecoration(
                  labelText: "Gênero (opcional)",
                  helperText: "Campo opcional - pode deixar em branco",
                ),
              ),
              // Plataforma (obrigatório)
              TextFormField(
                controller: platformController,
                decoration: const InputDecoration(labelText: "Plataforma"),
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha a plataforma' : null,
              ),
              // URL da Imagem (obrigatório)
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: "URL da Imagem",
                  hintText: "Ex: https://videogames-api-bbf46be3e1a8.herokuapp.com/images/banner1.png",
                  helperText: "URLs que funcionam: banner1.png, banner2.png, banner3.png",
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha a URL da imagem' : null,
                onChanged: (value) {
                  // Atualiza o preview da imagem quando a URL muda
                  setState(() {});
                },
              ),
              // Preview da imagem
              if (imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Preview da Imagem:"),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrlController.text,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50),
                                Text("Imagem não encontrada"),
                                Text("Verifique a URL", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              // Botões de ação
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveGame,
                      child: const Text("Salvar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                  ),
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final confirm = await showConfirmDialog(context);
                      if (confirm == true) {
                        deleteGame();
                      }
                    },
                    child: const Text("Excluir"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  // Libera todos os controllers para evitar vazamento de memória
  void dispose() {
    nameController.dispose();
    genreController.dispose();
    platformController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(const GamesApp());
}

class GamesApp extends StatelessWidget {
  const GamesApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Games App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}