$$
\begin{align}
    [\text{prog}] &\to [\text{stmt}]^* \\
    [\text{stmt}] &\to
    \begin{cases}
        \text{exit}([\text{expr}]); \\
        \text{let}\ [\text{ident}] = [\text{expr}];
    \end{cases} \\
    [\text{exit}] &\to \text{exit}([\text{expr}]); \\
    [\text{expr}] &\to \text{int\_lit}
\end{align}
$$