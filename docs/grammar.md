$$
\begin{align}
    [\text{Prog}] &\to [\text{stmt}]^* \\
    [\text{Stmt}] &\to
    \begin{cases}
        \text{exit}([\text{Expr}]); \\
        \text{let}\ [\text{Ident}] = [\text{Expr}];
    \end{cases} \\
    [\text{Expr}] &\to
    \begin{cases}
        \text{int\_lit}\\
        \text{[Ident]} \\
        \text{[BinExpr]}  
    \end{cases}\\
    [\text{BinExpr}] &\to 
    \begin{cases}
        [\text{Expr}] * [\text{Expr}] & \text{prec} = 1 \\
        [\text{Expr}] + [\text{Expr}] & \text{prec} = 0 \\
        [\text{Expr}] - [\text{Expr}] \\
        [\text{Expr}] / [\text{Expr}] \\
        [\text{Expr}] \% [\text{Expr}] \\
    \end{cases}
\end{align}
$$