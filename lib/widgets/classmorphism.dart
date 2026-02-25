// import 'package:flutter/material.dart';

// class GlassAuditCard extends StatelessWidget {
//   final Color color;
//   final Widget child;

//   const GlassAuditCard({
//     super.key,
//     required this.color,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               color.withOpacity(0.25),
//               color.withOpacity(0.05),
//             ],
//           ),
//           border: Border.all(
//             color: color.withOpacity(0.4),
//           ),
//         ),
//         child: child,
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
class AuditCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const AuditCard({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // LEFT COLOR STRIPE
            Container(
              width: 6,
             
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
        
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}



