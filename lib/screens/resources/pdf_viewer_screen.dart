import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  PdfTextSearchResult? _searchResult;

  @override
  void dispose() {
    _controller.dispose();
    _searchCtrl.dispose();
    _searchResult?.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchResult?.clear();
        _searchResult = null;
        _searchCtrl.clear();
      }
    });
  }

  void _runSearch(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchResult?.dispose();
      _searchResult = _controller.searchText(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, color: AppTheme.primary),
            tooltip: 'Search in PDF',
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.first_page, color: cs.onSurfaceVariant),
            tooltip: 'First page',
            onPressed: () => _controller.jumpToPage(1),
          ),
          IconButton(
            icon: Icon(Icons.last_page, color: cs.onSurfaceVariant),
            tooltip: 'Last page',
            onPressed: () => _controller.jumpToPage(_controller.pageCount),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Container(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search in PDF...',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: cs.onSurface),
                      onSubmitted: _runSearch,
                    ),
                  ),
                  if (_searchResult != null) ...[
                    IconButton(
                      icon: Icon(Icons.navigate_before, color: AppTheme.primary),
                      onPressed: () => _searchResult?.previousInstance(),
                    ),
                    IconButton(
                      icon: Icon(Icons.navigate_next, color: AppTheme.primary),
                      onPressed: () => _searchResult?.nextInstance(),
                    ),
                  ],
                  IconButton(
                    icon: Icon(Icons.search, color: AppTheme.primary),
                    onPressed: () => _runSearch(_searchCtrl.text),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SfPdfViewer.network(
              widget.url,
              controller: _controller,
              enableTextSelection: true,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoadFailed: (details) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to load PDF: ${details.description}'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
