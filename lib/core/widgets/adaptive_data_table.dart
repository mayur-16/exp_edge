
import 'package:flutter/material.dart';
import '../responsive/responsive_layout.dart';

/// Column definition for adaptive table
class AdaptiveTableColumn<T> {
  final String label;
  final String Function(T) getValue;
  final Widget Function(T)? buildCell;
  final double? width;
  final bool numeric;

  const AdaptiveTableColumn({
    required this.label,
    required this.getValue,
    this.buildCell,
    this.width,
    this.numeric = false,
  });
}

/// Adaptive table that shows DataTable on desktop and Cards on mobile
class AdaptiveDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<AdaptiveTableColumn<T>> columns;
  final void Function(T)? onTap;
  final Widget Function(T)? buildMobileCard;
  final List<PopupMenuEntry<String>> Function(T)? menuBuilder;
  final void Function(String, T)? onMenuSelected;
  final bool isLoading;

  const AdaptiveDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.onTap,
    this.buildMobileCard,
    this.menuBuilder,
    this.onMenuSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ResponsiveLayout(
      mobile: _buildMobileList(context),
      desktop: _buildDesktopTable(context),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        if (buildMobileCard != null) {
          return InkWell(
            onTap: onTap != null ? () => onTap!(item) : null,
            child: buildMobileCard!(item),
          );
        }

        // Default mobile card
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(columns[0].getValue(item)),
            subtitle: columns.length > 1
                ? Text(columns[1].getValue(item))
                : null,
            onTap: onTap != null ? () => onTap!(item) : null,
            trailing: menuBuilder != null
                ? PopupMenuButton<String>(
                    itemBuilder: (_) => menuBuilder!(item),
                    onSelected: (value) => onMenuSelected?.call(value, item),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: columns
                  .map((col) => DataColumn(
                        label: Text(
                          col.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: col.numeric,
                      ))
                  .toList(),
              rows: items.map((item) {
                return DataRow(
                  onSelectChanged: onTap != null ? (_) => onTap!(item) : null,
                  cells: columns.map((col) {
                    return DataCell(
                      col.buildCell != null
                          ? col.buildCell!(item)
                          : Text(col.getValue(item)),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}